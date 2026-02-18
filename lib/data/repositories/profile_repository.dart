import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/profile/customer_profile.dart';
import '../models/profile/scenario_session.dart';
import '../services/storage_service.dart';

class ProfileRepository {
  final StorageService _storage;

  ProfileRepository(this._storage);

  String _filePath(String id) => p.join(_storage.profilesDir, '$id.json');

  Future<List<CustomerProfile>> listAll() async {
    final dir = Directory(_storage.profilesDir);
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final profiles = <CustomerProfile>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        profiles.add(CustomerProfile.fromJson(json));
      } catch (_) {
        // Skip malformed files
      }
    }
    profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return profiles;
  }

  Future<CustomerProfile?> getById(String id) async {
    final file = File(_filePath(id));
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CustomerProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CustomerProfile profile) async {
    final file = File(_filePath(profile.id));
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(profile.toJson()));
  }

  Future<void> delete(String id) async {
    final file = File(_filePath(id));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Export profile JSON to an arbitrary file path (chosen by user via file picker).
  Future<void> exportToFile(CustomerProfile profile, String filePath) async {
    final file = File(filePath);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(profile.toJson()));
  }

  /// Remove a specific session from a profile and persist.
  Future<void> deleteSession(String profileId, String sessionId) async {
    final profile = await getById(profileId);
    if (profile == null) return;
    final sessions =
        profile.sessions.where((s) => s.id != sessionId).toList();
    final updated = profile.copyWith(
      sessions: sessions,
      updatedAt: DateTime.now(),
    );
    await save(updated);
  }

  /// Update a specific session within a profile and persist.
  Future<CustomerProfile> upsertSession(
      String profileId, ScenarioSession session) async {
    final profile = await getById(profileId);
    if (profile == null) throw StateError('Profile $profileId not found');

    final sessions = List<ScenarioSession>.from(profile.sessions);
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }

    final updated = profile.copyWith(
      sessions: sessions,
      updatedAt: DateTime.now(),
    );
    await save(updated);
    return updated;
  }
}
