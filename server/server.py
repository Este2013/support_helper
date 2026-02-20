"""
support_helper sync server
==========================
Thin JSON-file store that implements the REST API consumed by the Flutter app.

Endpoints
---------
  GET  /api/ping                        Health check (no auth required)
  GET  /api/me                          Returns caller's role
  GET  /api/scenarios                   Metadata list [{id, version, updatedAt, name}]
  GET  /api/scenarios/{id}/{version}    Full scenario JSON
  PUT  /api/scenarios/{id}/{version}    Upsert scenario  (editor only)
  DELETE /api/scenarios/{id}/{version}  Delete scenario  (editor only)
  GET  /api/profiles                    Metadata list [{id, updatedAt}]
  GET  /api/profiles/{id}              Full profile JSON
  PUT  /api/profiles/{id}              Upsert profile   (editor only)
  DELETE /api/profiles/{id}            Delete profile   (editor only)

Auth
----
All endpoints except /api/ping require:
  Authorization: Bearer <token>

Tokens are configured in tokens.json:
  { "my-secret-token": "editor", "read-only-token": "viewer" }

Storage
-------
  data/scenarios/{id}_v{version}.json
  data/profiles/{id}.json

Run
---
  python server.py
  # or with auto-reload for development:
  uvicorn server:app --reload
"""

import json
import os
from pathlib import Path
from typing import Annotated, Any

import uvicorn
from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).parent
TOKENS_FILE = BASE_DIR / "tokens.json"
DATA_DIR = BASE_DIR / "data"
SCENARIOS_DIR = DATA_DIR / "scenarios"
PROFILES_DIR = DATA_DIR / "profiles"


def _load_tokens() -> dict[str, str]:
    if not TOKENS_FILE.exists():
        print(
            f"[WARN] {TOKENS_FILE} not found — no tokens configured. "
            "Create it with {\"<token>\": \"editor\"} to enable auth."
        )
        return {}
    with TOKENS_FILE.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"{TOKENS_FILE} must be a JSON object mapping token strings to roles.")
    return {str(k): str(v) for k, v in data.items()}


# Load once at startup; restart the server to pick up token changes.
TOKENS: dict[str, str] = _load_tokens()

# ---------------------------------------------------------------------------
# Ensure data directories exist
# ---------------------------------------------------------------------------

SCENARIOS_DIR.mkdir(parents=True, exist_ok=True)
PROFILES_DIR.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------

app = FastAPI(
    title="support_helper sync server",
    description="Thin JSON-file store for scenario and profile synchronisation.",
    version="1.0.0",
)

# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------


def _parse_bearer(authorization: str) -> str:
    """Extract the token from 'Bearer <token>'."""
    parts = authorization.strip().split(" ", 1)
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail={"message": "Invalid Authorization header. Expected: Bearer <token>"})
    return parts[1]


def get_role(authorization: Annotated[str | None, Header()] = None) -> str:
    """FastAPI dependency — resolves the caller's role or raises 401/403."""
    if authorization is None:
        raise HTTPException(status_code=401, detail={"message": "Authorization header required"})
    token = _parse_bearer(authorization)
    role = TOKENS.get(token)
    if role is None:
        raise HTTPException(status_code=403, detail={"message": "Unknown token"})
    return role


def require_editor(role: Annotated[str, Depends(get_role)]) -> str:
    """FastAPI dependency — additionally asserts editor role."""
    if role != "editor":
        raise HTTPException(status_code=403, detail={"message": "Editor role required"})
    return role


# ---------------------------------------------------------------------------
# Error response formatter
#
# FastAPI raises HTTPException with detail={"message": "..."} so that the
# Flutter RemoteApiException can read the "message" field from the JSON body.
# ---------------------------------------------------------------------------


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    detail = exc.detail
    if isinstance(detail, dict):
        body = detail
    else:
        body = {"message": str(detail)}
    return JSONResponse(status_code=exc.status_code, content=body)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _scenario_path(scenario_id: str, version: str) -> Path:
    """Filename mirrors the Flutter app's ScenarioRepository convention."""
    return SCENARIOS_DIR / f"{scenario_id}_v{version}.json"


def _profile_path(profile_id: str) -> Path:
    return PROFILES_DIR / f"{profile_id}.json"


def _read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)


# ---------------------------------------------------------------------------
# Health check (no auth)
# ---------------------------------------------------------------------------


@app.get("/api/ping", tags=["health"])
async def ping() -> dict[str, bool]:
    """Health check — no authentication required."""
    return {"ok": True}


# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------


@app.get("/api/me", tags=["auth"])
async def me(role: Annotated[str, Depends(get_role)]) -> dict[str, str]:
    """Returns the authenticated caller's role (editor or viewer)."""
    return {"role": role}


# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------


@app.get("/api/scenarios", tags=["scenarios"])
async def list_scenarios(
    role: Annotated[str, Depends(get_role)],
) -> list[dict[str, str]]:
    """
    Returns metadata for all stored scenarios.
    Response: [{id, version, updatedAt, name}, ...]
    """
    result: list[dict[str, str]] = []
    for path in SCENARIOS_DIR.glob("*.json"):
        try:
            data = _read_json(path)
            result.append(
                {
                    "id": data["id"],
                    "version": data["version"],
                    "updatedAt": data["updatedAt"],
                    "name": data.get("name", data["id"]),
                }
            )
        except Exception as exc:
            # Log and skip corrupt files rather than failing the whole list.
            print(f"[WARN] Skipping {path.name}: {exc}")
    return result


@app.get("/api/scenarios/{scenario_id}/{version}", tags=["scenarios"])
async def get_scenario(
    scenario_id: str,
    version: str,
    role: Annotated[str, Depends(get_role)],
) -> dict[str, Any]:
    """Returns the full JSON for a specific scenario version."""
    path = _scenario_path(scenario_id, version)
    if not path.exists():
        raise HTTPException(
            status_code=404,
            detail={"message": f"Scenario not found: {scenario_id} v{version}"},
        )
    return _read_json(path)


@app.put("/api/scenarios/{scenario_id}/{version}", tags=["scenarios"])
async def upsert_scenario(
    scenario_id: str,
    version: str,
    request: Request,
    _role: Annotated[str, Depends(require_editor)],
) -> dict[str, bool]:
    """Creates or replaces a scenario. Requires editor role."""
    body = await request.json()
    path = _scenario_path(scenario_id, version)
    _write_json(path, body)
    print(f"[PUT] Saved scenario {scenario_id} v{version} → {path.name}")
    return {"ok": True}


@app.delete("/api/scenarios/{scenario_id}/{version}", tags=["scenarios"])
async def delete_scenario(
    scenario_id: str,
    version: str,
    _role: Annotated[str, Depends(require_editor)],
) -> dict[str, bool]:
    """Deletes a scenario. Requires editor role."""
    path = _scenario_path(scenario_id, version)
    if not path.exists():
        raise HTTPException(
            status_code=404,
            detail={"message": f"Scenario not found: {scenario_id} v{version}"},
        )
    path.unlink()
    print(f"[DELETE] Removed scenario {scenario_id} v{version}")
    return {"ok": True}


# ---------------------------------------------------------------------------
# Profiles
# ---------------------------------------------------------------------------


@app.get("/api/profiles", tags=["profiles"])
async def list_profiles(
    role: Annotated[str, Depends(get_role)],
) -> list[dict[str, str]]:
    """
    Returns metadata for all stored profiles.
    Response: [{id, updatedAt}, ...]
    """
    result: list[dict[str, str]] = []
    for path in PROFILES_DIR.glob("*.json"):
        try:
            data = _read_json(path)
            result.append(
                {
                    "id": data["id"],
                    "updatedAt": data["updatedAt"],
                }
            )
        except Exception as exc:
            print(f"[WARN] Skipping {path.name}: {exc}")
    return result


@app.get("/api/profiles/{profile_id}", tags=["profiles"])
async def get_profile(
    profile_id: str,
    role: Annotated[str, Depends(get_role)],
) -> dict[str, Any]:
    """Returns the full JSON for a specific profile."""
    path = _profile_path(profile_id)
    if not path.exists():
        raise HTTPException(
            status_code=404,
            detail={"message": f"Profile not found: {profile_id}"},
        )
    return _read_json(path)


@app.put("/api/profiles/{profile_id}", tags=["profiles"])
async def upsert_profile(
    profile_id: str,
    request: Request,
    _role: Annotated[str, Depends(require_editor)],
) -> dict[str, bool]:
    """Creates or replaces a profile. Requires editor role."""
    body = await request.json()
    path = _profile_path(profile_id)
    _write_json(path, body)
    print(f"[PUT] Saved profile {profile_id} → {path.name}")
    return {"ok": True}


@app.delete("/api/profiles/{profile_id}", tags=["profiles"])
async def delete_profile(
    profile_id: str,
    _role: Annotated[str, Depends(require_editor)],
) -> dict[str, bool]:
    """Deletes a profile. Requires editor role."""
    path = _profile_path(profile_id)
    if not path.exists():
        raise HTTPException(
            status_code=404,
            detail={"message": f"Profile not found: {profile_id}"},
        )
    path.unlink()
    print(f"[DELETE] Removed profile {profile_id}")
    return {"ok": True}


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("support_helper sync server")
    print(f"  Tokens loaded: {len(TOKENS)} ({', '.join(TOKENS.keys()) if TOKENS else 'none'})")
    print(f"  Scenarios dir: {SCENARIOS_DIR.resolve()}")
    print(f"  Profiles dir:  {PROFILES_DIR.resolve()}")
    print("  Docs: http://localhost:8000/docs")
    print()
    uvicorn.run(app, host="0.0.0.0", port=8000)
