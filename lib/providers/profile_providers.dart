import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/profile/customer_profile.dart';
import '../data/repositories/profile_repository.dart';
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
