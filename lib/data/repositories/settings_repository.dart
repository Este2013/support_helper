import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/settings/app_settings.dart';
import '../services/storage_service.dart';

/// Secure-storage key for the API bearer token.
/// All other settings live in [StorageService.settingsFilePath] as plain JSON.
const _tokenKey = 'support_helper.authToken';

/// Reads and writes [AppSettings] using two storage locations:
/// - Non-sensitive fields → `settings.json` (plain JSON, same pattern as other repos)
/// - [AppSettings.authToken] → platform secure store ([FlutterSecureStorage])
///   which uses Windows Credential Manager on desktop.
class SettingsRepository {
  final StorageService _storage;
  final FlutterSecureStorage _secure;

  SettingsRepository(this._storage, this._secure);

  /// Loads settings from disk. Non-sensitive fields come from `settings.json`;
  /// the token is merged in from the platform secure store.
  /// Returns [AppSettings()] defaults if the file does not exist or cannot be parsed.
  Future<AppSettings> load() async {
    // 1. Load non-sensitive fields from JSON.
    AppSettings base = const AppSettings();
    final file = File(_storage.settingsFilePath);
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        base = AppSettings.fromJson(json); // authToken is ignored by fromJson
      } catch (_) {
        // Corrupt or unreadable file — fall back to defaults.
      }
    }

    // 2. Merge token from secure storage.
    final token = await _secure.read(key: _tokenKey);
    return base.copyWith(authToken: token);
  }

  /// Persists [settings] to disk and secure storage.
  /// Non-sensitive fields are written to `settings.json`; the token is stored
  /// in the platform secure store (authToken is excluded from toJson).
  Future<void> save(AppSettings settings) async {
    // Write non-sensitive fields to JSON.
    final file = File(_storage.settingsFilePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );

    // Write token to secure storage, or delete if cleared.
    final token = settings.authToken;
    if (token != null && token.isNotEmpty) {
      await _secure.write(key: _tokenKey, value: token);
    } else {
      await _secure.delete(key: _tokenKey);
    }
  }
}
