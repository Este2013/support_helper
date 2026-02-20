# support_helper sync server

A minimal Python/FastAPI server that implements the REST API used by the
support_helper Flutter app. It stores scenarios and profiles as JSON files on
disk — the same format the app uses locally.

---

## Prerequisites

- Python 3.9 or later
- pip

---

## Setup

```bash
cd server
pip install -r requirements.txt
```

---

## Configure tokens

Edit `tokens.json`. Each key is a token string, each value is either
`"editor"` (can push) or `"viewer"` (pull only):

```json
{
  "dev-editor-token": "editor",
  "dev-viewer-token": "viewer"
}
```

Add or remove entries as needed. Restart the server to reload the token file.

> **Tip:** Generate secure tokens with `python -c "import secrets; print(secrets.token_hex(32))"`.

---

## Run

```bash
# Production-style (no reload)
python server.py

# Development (auto-reloads on code changes)
uvicorn server:app --reload
```

The server starts on `http://0.0.0.0:8000`.

---

## Interactive API docs

Open **http://localhost:8000/docs** in your browser for FastAPI's built-in
Swagger UI. Every endpoint is listed with request/response schemas and a
"Try it out" button.

---

## Connect the Flutter app

1. Open the app and click the **settings icon** at the bottom of the left navigation rail.
2. Enter `http://localhost:8000` as the **Server URL**.
3. Paste one of your tokens into the **API Token** field.
4. Click **Test Connection** — the banner should show your role (Editor or Viewer).
5. Click **Sync Now** to pull any existing scenarios from the server.

---

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/ping` | none | Health check → `{"ok": true}` |
| `GET` | `/api/me` | any | Returns caller's role |
| `GET` | `/api/scenarios` | any | Scenario metadata list |
| `GET` | `/api/scenarios/{id}/{version}` | any | Full scenario JSON |
| `PUT` | `/api/scenarios/{id}/{version}` | editor | Upsert scenario |
| `DELETE` | `/api/scenarios/{id}/{version}` | editor | Delete scenario |
| `GET` | `/api/profiles` | any | Profile metadata list |
| `GET` | `/api/profiles/{id}` | any | Full profile JSON |
| `PUT` | `/api/profiles/{id}` | editor | Upsert profile |
| `DELETE` | `/api/profiles/{id}` | editor | Delete profile |

Authentication uses `Authorization: Bearer <token>` on all endpoints except
`/api/ping`.

---

## Storage layout

```
server/
├── data/
│   ├── scenarios/
│   │   └── {id}_v{version}.json   # e.g. network-troubleshoot_v2.1.json
│   └── profiles/
│       └── {id}.json              # e.g. a1b2c3d4-uuid.json
├── tokens.json
├── server.py
└── requirements.txt
```

The `data/` directory is created automatically on first run. You can seed it
with scenario files copied from the Flutter app's local scenarios folder
(`%AppData%\support_helper\scenarios\` on Windows).

---

## Verification checklist

1. `python server.py` starts without errors; tokens are listed in the console.
2. `curl http://localhost:8000/api/ping` → `{"ok":true}`
3. Flutter app — Test Connection with editor token → "Connected. Role: Editor"
4. Flutter app — Test Connection with viewer token → "Connected. Role: Viewer"
5. Flutter app — Test Connection with a bad token → error message shown
6. Flutter app — create and publish a scenario → file appears in `data/scenarios/`
7. Flutter app — Sync Now pulls that file back when testing on a fresh install
8. Flutter app — enable profile sync; create/update a profile → file appears in `data/profiles/`
9. Viewer token — edit + save a scenario → local save succeeds, no PUT reaches server
