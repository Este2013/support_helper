import '../models/profile/customer_profile.dart';
import '../models/scenario/scenario.dart' show ScenarioSource;
import '../repositories/profile_repository.dart';
import 'remote_api_client.dart';
import 'scenario_sync_service.dart' show SyncResult;

/// Coordinates profile synchronisation between the local [ProfileRepository]
/// and the remote server via [RemoteApiClient].
///
/// Only active when [AppSettings.syncProfilesEnabled] is true.
/// Follows the same pull/push semantics as [ScenarioSyncService]:
/// - Pull: downloads profiles newer than local (last-writer-wins by updatedAt)
/// - Push: uploads a single profile after a local save (editor role only)
class ProfileSyncService {
  final ProfileRepository _local;
  final RemoteApiClient _remote;

  ProfileSyncService(this._local, this._remote);

  /// Pulls all profiles from the server.
  ///
  /// Overwrites the local profile if the server version is strictly newer
  /// (serverUpdatedAt > localUpdatedAt). Sets [source = remote] on pulled
  /// profiles.
  Future<SyncResult> pullAll() async {
    final List<dynamic> metaList;
    try {
      metaList = await _remote.getList('/api/profiles');
    } on RemoteApiException {
      rethrow;
    }

    int pulled = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final raw in metaList) {
      final meta = raw as Map<String, dynamic>;
      final id = meta['id'] as String;
      final serverUpdatedAt =
          DateTime.tryParse(meta['updatedAt'] as String? ?? '');

      try {
        final local = await _local.getById(id);
        if (local != null &&
            serverUpdatedAt != null &&
            !local.updatedAt.isBefore(serverUpdatedAt)) {
          skipped++;
          continue;
        }

        final profileJson = await _remote.get('/api/profiles/$id');
        final profile = CustomerProfile.fromJson(profileJson)
            .copyWith(source: ScenarioSource.remote);
        await _local.save(profile);
        pulled++;
      } catch (e) {
        errors.add('$id: $e');
      }
    }

    return SyncResult(pulled: pulled, skipped: skipped, errors: errors);
  }

  /// Pushes [profile] to the server.
  ///
  /// Throws [RemoteApiException] on network/server failure.
  Future<void> push(CustomerProfile profile) async {
    await _remote.put('/api/profiles/${profile.id}', profile.toJson());
  }
}
