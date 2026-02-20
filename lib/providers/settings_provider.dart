import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/settings/app_settings.dart';
import '../data/repositories/settings_repository.dart';
import 'storage_provider.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  final storage = ref.watch(storageServiceProvider).requireValue;
  // WindowsOptions(useBackwardCompatibility: false) uses modern DPAPI encryption.
  const secure = FlutterSecureStorage(
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );
  return SettingsRepository(storage, secure);
}

/// Loads [AppSettings] from disk and exposes a mutation method to persist
/// changes. Kept alive so the settings are loaded once and remain available
/// across the entire app lifetime.
@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return ref.read(settingsRepositoryProvider).load();
  }

  /// Persists [settings] to disk and updates the in-memory state immediately.
  Future<void> save(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }

  /// Convenience getter — returns current settings or defaults if not yet
  /// loaded. Safe to call synchronously after initial load.
  AppSettings get current =>
      state.valueOrNull ?? const AppSettings();
}
