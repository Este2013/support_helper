import '../datasources/scenario_data_source.dart';
import '../models/scenario/scenario.dart';
import 'remote_api_client.dart';

/// Lightweight metadata record returned by [ScenarioSyncService.fetchMetaList].
/// Used by the list provider to merge remote entries with local ones without
/// downloading full scenario JSON.
class ScenarioRemoteMeta {
  final String id;
  final String version;
  final DateTime updatedAt;

  /// Display name from the server metadata response. Falls back to [id] when
  /// the server does not include a name field (older server versions).
  final String name;

  const ScenarioRemoteMeta({
    required this.id,
    required this.version,
    required this.updatedAt,
    required this.name,
  });
}

/// Result of a [ScenarioSyncService.pullAll] operation.
class SyncResult {
  /// Number of scenarios that were downloaded and written to local disk.
  final int pulled;

  /// Number of scenarios that were skipped (local version up-to-date, or
  /// a local draft was present and was not overwritten).
  final int skipped;

  /// Any non-fatal errors encountered during the sync (e.g. a single scenario
  /// failing to download). The sync continues despite per-item errors.
  final List<String> errors;

  const SyncResult({
    this.pulled = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'SyncResult(pulled: $pulled, skipped: $skipped, errors: ${errors.length})';
}

/// Coordinates scenario synchronisation between the local [ScenarioDataSource]
/// and the remote server via [RemoteApiClient].
///
/// Pull semantics:
///   - Downloads scenarios from the server that are newer than the local copy
///     (or that don't exist locally), saving them with [ScenarioSource.remote].
///   - Never overwrites a local draft — scenarios with an active draft are
///     skipped to protect in-progress editing work.
///
/// Push semantics (editor role only):
///   - Uploads a single scenario to the server after a successful local save.
///   - Throws [RemoteApiException] on failure; the caller decides how to
///     surface this (the local save has already succeeded at that point).
class ScenarioSyncService {
  final ScenarioDataSource _local;
  final RemoteApiClient _remote;

  ScenarioSyncService(this._local, this._remote);

  // ── Metadata list ─────────────────────────────────────────────────────────

  /// Fetches only the lightweight metadata list from the server
  /// (`GET /api/scenarios`) without downloading any full scenario JSON.
  ///
  /// Used by [scenarioRemoteMetaProvider] to merge remote scenario stubs into
  /// the list panel without triggering a full sync.
  ///
  /// Throws [RemoteApiException] on connectivity failure.
  Future<List<ScenarioRemoteMeta>> fetchMetaList() async {
    final raw = await _remote.getList('/api/scenarios');
    return [
      for (final item in raw)
        ScenarioRemoteMeta(
          id: item['id'] as String,
          version: item['version'] as String,
          updatedAt: DateTime.parse(item['updatedAt'] as String),
          name: item['name'] as String? ?? item['id'] as String,
        ),
    ];
  }

  // ── Pull ──────────────────────────────────────────────────────────────────

  /// Pulls all scenarios from the server.
  ///
  /// For each remote entry:
  ///   1. If a local draft exists → skip (don't overwrite active work).
  ///   2. If local published file is up-to-date (localUpdatedAt >= serverUpdatedAt) → skip.
  ///   3. Otherwise fetch the full JSON and save locally with [source = remote].
  Future<SyncResult> pullAll() async {
    final metaList = await fetchMetaList();

    int pulled = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final meta in metaList) {
      final id = meta.id;
      final version = meta.version;

      try {
        // 1. Skip if a local draft exists — never clobber active editing work.
        final draft = await _local.loadDraft(id, version);
        if (draft != null) {
          skipped++;
          continue;
        }

        // 2. Skip if local published file is already up-to-date.
        final local = await _local.getById(id, version);
        if (local != null &&
            !local.updatedAt.isBefore(meta.updatedAt)) {
          skipped++;
          continue;
        }

        // 3. Fetch full scenario and save locally with source = remote.
        final scenarioJson =
            await _remote.get('/api/scenarios/$id/$version');
        final scenario = Scenario.fromJson(scenarioJson)
            .copyWith(source: ScenarioSource.remote);
        await _local.save(scenario);
        pulled++;
      } catch (e) {
        errors.add('$id v$version: $e');
      }
    }

    return SyncResult(pulled: pulled, skipped: skipped, errors: errors);
  }

  // ── Push ──────────────────────────────────────────────────────────────────

  /// Pushes [scenario] to the server (`PUT /api/scenarios/{id}/{version}`).
  ///
  /// Throws [RemoteApiException] on network/server failure.
  /// Callers should check [AppSettings.canPush] before calling this.
  Future<void> push(Scenario scenario) async {
    await _remote.put(
      '/api/scenarios/${scenario.id}/${scenario.version}',
      scenario.toJson(),
    );
  }

  /// Fetches and returns a single full scenario from the server.
  /// Used by the list panel to pull a remote-only scenario on demand
  /// (e.g. "Download to edit" or "Open from server").
  ///
  /// Returns the scenario with [source = ScenarioSource.remote].
  /// Throws [RemoteApiException] on failure.
  Future<Scenario> fetchOne(String id, String version) async {
    final json = await _remote.get('/api/scenarios/$id/$version');
    return Scenario.fromJson(json).copyWith(source: ScenarioSource.remote);
  }
}
