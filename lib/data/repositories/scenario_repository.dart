import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/scenario/scenario.dart';
import '../services/storage_service.dart';

class ScenarioRepository {
  final StorageService _storage;

  ScenarioRepository(this._storage);

  String _filePath(String id, String version) =>
      p.join(_storage.scenariosDir, '${id}_v$version.json');

  Future<List<Scenario>> listAll() async {
    final dir = Directory(_storage.scenariosDir);
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final scenarios = <Scenario>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        scenarios.add(Scenario.fromJson(json));
      } catch (_) {
        // Skip malformed files
      }
    }
    scenarios.sort((a, b) => a.name.compareTo(b.name));
    return scenarios;
  }

  Future<Scenario?> getById(String id, String version) async {
    final file = File(_filePath(id, version));
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Scenario.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Scenario scenario) async {
    final file = File(_filePath(scenario.id, scenario.version));
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(scenario.toJson()));
  }

  Future<void> delete(String id, String version) async {
    final file = File(_filePath(id, version));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Import a scenario from an arbitrary JSON file path.
  Future<Scenario> importFromFile(String sourcePath) async {
    final file = File(sourcePath);
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final scenario = Scenario.fromJson(json);
    await save(scenario);
    return scenario;
  }

  /// Returns the file path for export (caller opens it via file_picker).
  Future<void> exportToFile(Scenario scenario, String destPath) async {
    final file = File(destPath);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(scenario.toJson()));
  }
}
