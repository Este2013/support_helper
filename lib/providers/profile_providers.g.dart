// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'086248b9f74c03171f108577e409540859e5bf5c';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider = Provider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = ProviderRef<ProfileRepository>;
String _$profileListHash() => r'0e40311956fc6da31b9c04120c8ccfc4b2d06e9e';

/// See also [profileList].
@ProviderFor(profileList)
final profileListProvider = FutureProvider<List<CustomerProfile>>.internal(
  profileList,
  name: r'profileListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileListRef = FutureProviderRef<List<CustomerProfile>>;
String _$profileByIdHash() => r'1906321cc976ac898a7a5732a9bbb954277c5b3d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [profileById].
@ProviderFor(profileById)
const profileByIdProvider = ProfileByIdFamily();

/// See also [profileById].
class ProfileByIdFamily extends Family<AsyncValue<CustomerProfile?>> {
  /// See also [profileById].
  const ProfileByIdFamily();

  /// See also [profileById].
  ProfileByIdProvider call(String profileId) {
    return ProfileByIdProvider(profileId);
  }

  @override
  ProfileByIdProvider getProviderOverride(
    covariant ProfileByIdProvider provider,
  ) {
    return call(provider.profileId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profileByIdProvider';
}

/// See also [profileById].
class ProfileByIdProvider extends AutoDisposeFutureProvider<CustomerProfile?> {
  /// See also [profileById].
  ProfileByIdProvider(String profileId)
    : this._internal(
        (ref) => profileById(ref as ProfileByIdRef, profileId),
        from: profileByIdProvider,
        name: r'profileByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$profileByIdHash,
        dependencies: ProfileByIdFamily._dependencies,
        allTransitiveDependencies: ProfileByIdFamily._allTransitiveDependencies,
        profileId: profileId,
      );

  ProfileByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    FutureOr<CustomerProfile?> Function(ProfileByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProfileByIdProvider._internal(
        (ref) => create(ref as ProfileByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CustomerProfile?> createElement() {
    return _ProfileByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileByIdProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileByIdRef on AutoDisposeFutureProviderRef<CustomerProfile?> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _ProfileByIdProviderElement
    extends AutoDisposeFutureProviderElement<CustomerProfile?>
    with ProfileByIdRef {
  _ProfileByIdProviderElement(super.provider);

  @override
  String get profileId => (origin as ProfileByIdProvider).profileId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
