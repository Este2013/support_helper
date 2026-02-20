import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/profile/customer_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/remote_api_client.dart';
import '../data/services/profile_sync_service.dart';
import 'settings_provider.dart';
import 'storage_provider.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final storage = ref.watch(storageServiceProvider).requireValue;
  return ProfileRepository(storage);
}

@Riverpod(keepAlive: true)
Future<List<CustomerProfile>> profileList(ProfileListRef ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.listAll();
}

@riverpod
Future<CustomerProfile?> profileById(
    ProfileByIdRef ref, String profileId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getById(profileId);
}

/// Returns a [ProfileSyncService] when a server is configured AND profile sync
/// is enabled, null otherwise. Kept alive so the [RemoteApiClient] is reused.
@Riverpod(keepAlive: true)
ProfileSyncService? profileSyncService(ProfileSyncServiceRef ref) {
  final settings = ref.watch(appSettingsNotifierProvider).valueOrNull;
  if (settings == null || !settings.hasServer || !settings.syncProfilesEnabled) {
    return null;
  }
  final local = ref.watch(profileRepositoryProvider);
  final client = RemoteApiClient(
    baseUrl: settings.serverUrl!,
    authToken: settings.authToken,
  );
  ref.onDispose(client.dispose);
  return ProfileSyncService(local, client);
}
