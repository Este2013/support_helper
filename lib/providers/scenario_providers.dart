import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/scenario/scenario.dart';
import '../data/repositories/scenario_repository.dart';
import 'storage_provider.dart';

part 'scenario_providers.g.dart';

@Riverpod(keepAlive: true)
ScenarioRepository scenarioRepository(ScenarioRepositoryRef ref) {
  final storage = ref.watch(storageServiceProvider).requireValue;
  return ScenarioRepository(storage);
}

@Riverpod(keepAlive: true)
Future<List<Scenario>> scenarioList(ScenarioListRef ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return repo.listAll();
}

/// A combined view of all published scenarios and any orphan drafts
/// (drafts with no corresponding published file).
///
/// Each entry carries:
/// - [scenario]        — the scenario data (published or draft)
/// - [hasDraft]        — true if a `.draft.json` exists for this id+version
/// - [publishedExists] — false for entries that only exist as a draft
@Riverpod(keepAlive: true)
Future<List<({Scenario scenario, bool hasDraft, bool publishedExists})>>
    scenarioListWithStatus(ScenarioListWithStatusRef ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  final published = await repo.listAll();
  final drafts = await repo.listAllDrafts();

  // Build a set of (id, version) keys that have a published file.
  final publishedKeys = {for (final s in published) '${s.id}|${s.version}'};
  // Build a set of (id, version) keys that have a draft file.
  final draftKeys = {for (final d in drafts) '${d.id}|${d.version}'};

  final result =
      <({Scenario scenario, bool hasDraft, bool publishedExists})>[];

  // All published entries — annotated with whether a draft also exists.
  for (final s in published) {
    result.add((
      scenario: s,
      hasDraft: draftKeys.contains('${s.id}|${s.version}'),
      publishedExists: true,
    ));
  }

  // Orphan drafts — drafts that have no published counterpart.
  for (final d in drafts) {
    if (!publishedKeys.contains('${d.id}|${d.version}')) {
      result.add((
        scenario: d,
        hasDraft: true,
        publishedExists: false,
      ));
    }
  }

  result.sort((a, b) => a.scenario.name.compareTo(b.scenario.name));
  return result;
}

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
  // Caller must handle published == null (scenario not found).
  return (scenario: published!, hasDraft: false);
}
