import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../datasources/scenario_data_source.dart';
import '../models/scenario/scenario.dart';
import '../services/storage_service.dart';

/// Local-filesystem implementation of [ScenarioDataSource].
/// Uses `dart:io` to read/write JSON files under the app support directory.
/// Not available on web — use a remote data source there instead.
class ScenarioRepository implements ScenarioDataSource {
  final StorageService _storage;

  ScenarioRepository(this._storage);

  String _filePath(String id, String version) =>
      p.join(_storage.scenariosDir, '${id}_v$version.json');

  String _draftFilePath(String id, String version) =>
      p.join(_storage.scenariosDir, '${id}_v$version.draft.json');

  // ── Draft (auto-save) helpers ──────────────────────────────────────────────

  /// Returns the unsaved draft for [id]+[version], or null if none exists.
  Future<Scenario?> loadDraft(String id, String version) async {
    final file = File(_draftFilePath(id, version));
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Scenario.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Writes [scenario] to the draft file (does not touch the published file).
  Future<void> saveDraft(Scenario scenario) async {
    final file = File(_draftFilePath(scenario.id, scenario.version));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(scenario.toJson()));
  }

  /// Deletes the draft file, if any (called after a successful publish-save).
  Future<void> deleteDraft(String id, String version) async {
    final file = File(_draftFilePath(id, version));
    if (await file.exists()) await file.delete();
  }

  // ── List ──────────────────────────────────────────────────────────────────

  /// Returns all draft files that exist on disk (regardless of whether a
  /// published counterpart exists).
  Future<List<Scenario>> listAllDrafts() async {
    final dir = Directory(_storage.scenariosDir);
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.draft.json'))
        .cast<File>()
        .toList();

    final drafts = <Scenario>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        drafts.add(Scenario.fromJson(json));
      } catch (_) {
        // Skip malformed draft files
      }
    }
    return drafts;
  }

  Future<List<Scenario>> listAll() async {
    final dir = Directory(_storage.scenariosDir);
    final files = await dir
        .list()
        // Only published files — draft files end in .draft.json
        .where((e) =>
            e is File &&
            e.path.endsWith('.json') &&
            !e.path.endsWith('.draft.json'))
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

  /// Publishes [scenario] to the canonical JSON file and removes any draft.
  Future<void> save(Scenario scenario) async {
    final file = File(_filePath(scenario.id, scenario.version));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(scenario.toJson()));
    await deleteDraft(scenario.id, scenario.version);
  }

  Future<void> delete(String id, String version) async {
    final file = File(_filePath(id, version));
    if (await file.exists()) await file.delete();
    await deleteDraft(id, version);
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
