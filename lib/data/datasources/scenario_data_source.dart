import '../models/scenario/scenario.dart';

/// Platform-agnostic contract for reading and writing scenarios.
///
/// Desktop implementation: [ScenarioRepository] — `dart:io` local JSON files.
/// Web implementation (future): `RemoteScenarioDataSource` — HTTP-only, no
/// local filesystem. Draft methods are no-ops; import/export throw
/// [UnsupportedError].
///
/// All providers and notifiers above this layer reference [ScenarioDataSource]
/// only — never a concrete type — so switching implementations at build time
/// requires no changes outside `scenario_providers.dart`.
abstract interface class ScenarioDataSource {
  // ── Published scenarios ───────────────────────────────────────────────────

  /// Returns all published scenarios (no drafts).
  Future<List<Scenario>> listAll();

  /// Returns a specific published scenario, or null if not found.
  Future<Scenario?> getById(String id, String version);

  /// Writes [scenario] as the canonical published file and removes any draft.
  Future<void> save(Scenario scenario);

  /// Deletes the published file (and any draft) for [id]+[version].
  Future<void> delete(String id, String version);

  // ── Drafts (local-only; no-op on web) ────────────────────────────────────

  /// Returns all draft scenarios (orphan and otherwise).
  /// Returns an empty list on web.
  Future<List<Scenario>> listAllDrafts();

  /// Returns the draft for [id]+[version], or null if none exists.
  /// Returns null on web.
  Future<Scenario?> loadDraft(String id, String version);

  /// Persists [scenario] as a draft (debounced auto-save).
  /// No-op on web.
  Future<void> saveDraft(Scenario scenario);

  /// Deletes the draft for [id]+[version].
  /// No-op on web.
  Future<void> deleteDraft(String id, String version);

  // ── File import / export (desktop-only) ──────────────────────────────────

  /// Imports a scenario from a JSON file at [sourcePath], saves it locally,
  /// and returns the parsed [Scenario].
  ///
  /// Throws [UnsupportedError] on web.
  Future<Scenario> importFromFile(String sourcePath);

  /// Exports [scenario] as a JSON file to [destPath].
  ///
  /// Throws [UnsupportedError] on web.
  Future<void> exportToFile(Scenario scenario, String destPath);
}
