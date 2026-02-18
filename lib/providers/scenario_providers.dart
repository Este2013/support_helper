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

@riverpod
Future<Scenario?> scenarioById(
    ScenarioByIdRef ref, String id, String version) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return repo.getById(id, version);
}
