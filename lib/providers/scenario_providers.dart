import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasources/scenario_data_source.dart';
import '../data/models/scenario/scenario.dart';
import '../data/repositories/scenario_repository.dart';
import '../data/services/remote_api_client.dart';
import '../data/services/scenario_sync_service.dart';
import 'settings_provider.dart';
import 'storage_provider.dart';

export '../data/services/scenario_sync_service.dart' show ScenarioRemoteMeta;

part 'scenario_providers.g.dart';

/// The active [ScenarioDataSource] implementation.
///
/// Desktop: [ScenarioRepository] (local `dart:io` JSON files).
/// Web (future): swap to `RemoteScenarioDataSource` here — nothing else changes.
@Riverpod(keepAlive: true)
ScenarioDataSource scenarioRepository(ScenarioRepositoryRef ref) {
  final storage = ref.watch(storageServiceProvider).requireValue;
  return ScenarioRepository(storage);
}

@Riverpod(keepAlive: true)
Future<List<Scenario>> scenarioList(ScenarioListRef ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return repo.listAll();
}

// ── Remote metadata ───────────────────────────────────────────────────────────

/// Fetches lightweight metadata from the server without downloading full
/// scenarios. Returns an empty list when no server is configured or when the
/// server is unreachable (best-effort — the local list is unaffected).
@Riverpod(keepAlive: true)
Future<List<ScenarioRemoteMeta>> scenarioRemoteMeta(
    ScenarioRemoteMetaRef ref) async {
  final syncService = ref.watch(scenarioSyncServiceProvider);
  if (syncService == null) return const [];
  try {
    return await syncService.fetchMetaList();
  } catch (_) {
    return const [];
  }
}

// ── Combined list ─────────────────────────────────────────────────────────────

/// A combined view of published scenarios, orphan drafts, and remote-only
/// scenarios (those known on the server but not yet pulled locally).
///
/// Each entry carries:
/// - [scenario]        — the scenario data (published, draft, or synthetic remote stub)
/// - [hasDraft]        — true if a `.draft.json` exists for this id+version
/// - [publishedExists] — false for entries that exist only as a draft or are remote-only
/// - [remoteExists]    — true if the server has this id+version
/// - [remoteIsNewer]   — true if server's updatedAt is strictly after the local file's
@Riverpod(keepAlive: true)
Future<
    List<({
      Scenario scenario,
      bool hasDraft,
      bool publishedExists,
      bool remoteExists,
      bool remoteIsNewer,
    })>> scenarioListWithStatus(ScenarioListWithStatusRef ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  final remoteMeta = await ref.watch(scenarioRemoteMetaProvider.future);

  final published = await repo.listAll();
  final drafts = await repo.listAllDrafts();

  final publishedKeys = {for (final s in published) '${s.id}|${s.version}'};
  final draftKeys = {for (final d in drafts) '${d.id}|${d.version}'};

  // Index remote metadata by "id|version" for O(1) lookup.
  final remoteByKey = {
    for (final m in remoteMeta) '${m.id}|${m.version}': m,
  };

  final result = <({
    Scenario scenario,
    bool hasDraft,
    bool publishedExists,
    bool remoteExists,
    bool remoteIsNewer,
  })>[];

  // Published local entries — annotated with remote status.
  for (final s in published) {
    final key = '${s.id}|${s.version}';
    final remote = remoteByKey[key];
    final remoteExists = remote != null;
    final remoteIsNewer =
        remoteExists && remote.updatedAt.isAfter(s.updatedAt);
    result.add((
      scenario: s,
      hasDraft: draftKeys.contains(key),
      publishedExists: true,
      remoteExists: remoteExists,
      remoteIsNewer: remoteIsNewer,
    ));
  }

  // Orphan drafts — drafts with no published counterpart.
  for (final d in drafts) {
    final key = '${d.id}|${d.version}';
    if (!publishedKeys.contains(key)) {
      final remote = remoteByKey[key];
      result.add((
        scenario: d,
        hasDraft: true,
        publishedExists: false,
        remoteExists: remote != null,
        remoteIsNewer: false, // draft takes precedence — irrelevant
      ));
    }
  }

  // Remote-only entries — on the server but not pulled locally yet.
  for (final meta in remoteMeta) {
    final key = '${meta.id}|${meta.version}';
    if (!publishedKeys.contains(key) && !draftKeys.contains(key)) {
      // Build a lightweight stub so the UI can display name + version.
      final stub = Scenario(
        id: meta.id,
        version: meta.version,
        name: meta.name,
        createdAt: meta.updatedAt,
        updatedAt: meta.updatedAt,
        source: ScenarioSource.remote,
      );
      result.add((
        scenario: stub,
        hasDraft: false,
        publishedExists: false,
        remoteExists: true,
        remoteIsNewer: true, // by definition: remote has it, local does not
      ));
    }
  }

  result.sort((a, b) => a.scenario.name.compareTo(b.scenario.name));
  return result;
}

// ── Sync service ──────────────────────────────────────────────────────────────

/// Returns a [ScenarioSyncService] when a server is configured, null otherwise.
/// Kept alive so the underlying [RemoteApiClient] is reused across calls.
@Riverpod(keepAlive: true)
ScenarioSyncService? scenarioSyncService(ScenarioSyncServiceRef ref) {
  final settings = ref.watch(appSettingsNotifierProvider).valueOrNull;
  if (settings == null || !settings.hasServer) return null;
  final local = ref.watch(scenarioRepositoryProvider);
  final client = RemoteApiClient(
    baseUrl: settings.serverUrl!,
    authToken: settings.authToken,
  );
  ref.onDispose(client.dispose);
  return ScenarioSyncService(local, client);
}

/// Fires a [ScenarioSyncService.pullAll] on first watch when a server is
/// configured, then invalidates the scenario list providers so the UI updates.
///
/// This is a fire-and-forget provider — the app shell watches it once at
/// startup. Returns null on success or when no server is configured;
/// the scenario list updates automatically via invalidation.
@Riverpod(keepAlive: true)
Future<void> scenarioStartupSync(ScenarioStartupSyncRef ref) async {
  final syncService = ref.watch(scenarioSyncServiceProvider);
  if (syncService == null) return;
  try {
    await syncService.pullAll();
    ref.invalidate(scenarioListProvider);
    ref.invalidate(scenarioListWithStatusProvider);
    ref.invalidate(scenarioRemoteMetaProvider);
  } catch (_) {
    // Startup pull is best-effort; ignore failures silently.
  }
}

// ── Per-scenario helpers ──────────────────────────────────────────────────────

@riverpod
Future<Scenario?> scenarioById(
    ScenarioByIdRef ref, String id, String version) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return repo.getById(id, version);
}

/// Loads a scenario for editing: returns the draft if one exists, otherwise
/// the published version. The bool indicates whether a draft was found.
@riverpod
Future<({Scenario scenario, bool hasDraft})> scenarioForEditing(
    ScenarioForEditingRef ref, String id, String version) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  final draft = await repo.loadDraft(id, version);
  if (draft != null) return (scenario: draft, hasDraft: true);
  final published = await repo.getById(id, version);
  return (scenario: published!, hasDraft: false);
}
