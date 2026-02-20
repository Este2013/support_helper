// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scenarioRepositoryHash() =>
    r'5222d4e8c177f5f1c3cec3b9439d51016b86a07f';

/// The active [ScenarioDataSource] implementation.
///
/// Desktop: [ScenarioRepository] (local `dart:io` JSON files).
/// Web (future): swap to `RemoteScenarioDataSource` here — nothing else changes.
///
/// Copied from [scenarioRepository].
@ProviderFor(scenarioRepository)
final scenarioRepositoryProvider = Provider<ScenarioDataSource>.internal(
  scenarioRepository,
  name: r'scenarioRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scenarioRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenarioRepositoryRef = ProviderRef<ScenarioDataSource>;
String _$scenarioListHash() => r'4ada6e6d2ec6d75407f0a9b51a52dde57f0efbab';

/// See also [scenarioList].
@ProviderFor(scenarioList)
final scenarioListProvider = FutureProvider<List<Scenario>>.internal(
  scenarioList,
  name: r'scenarioListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scenarioListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenarioListRef = FutureProviderRef<List<Scenario>>;
String _$scenarioRemoteMetaHash() =>
    r'7a21aedbe5e1b3d6a322c2966b158dc09292b87b';

/// Fetches lightweight metadata from the server without downloading full
/// scenarios. Returns an empty list when no server is configured or when the
/// server is unreachable (best-effort — the local list is unaffected).
///
/// Copied from [scenarioRemoteMeta].
@ProviderFor(scenarioRemoteMeta)
final scenarioRemoteMetaProvider =
    FutureProvider<List<ScenarioRemoteMeta>>.internal(
      scenarioRemoteMeta,
      name: r'scenarioRemoteMetaProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scenarioRemoteMetaHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenarioRemoteMetaRef = FutureProviderRef<List<ScenarioRemoteMeta>>;
String _$scenarioListWithStatusHash() =>
    r'220f33fb26041dc05acb593ff80112533bb82267';

/// A combined view of published scenarios, orphan drafts, and remote-only
/// scenarios (those known on the server but not yet pulled locally).
///
/// Each entry carries:
/// - [scenario]        — the scenario data (published, draft, or synthetic remote stub)
/// - [hasDraft]        — true if a `.draft.json` exists for this id+version
/// - [publishedExists] — false for entries that exist only as a draft or are remote-only
/// - [remoteExists]    — true if the server has this id+version
/// - [remoteIsNewer]   — true if server's updatedAt is strictly after the local file's
///
/// Copied from [scenarioListWithStatus].
@ProviderFor(scenarioListWithStatus)
final scenarioListWithStatusProvider =
    FutureProvider<
      List<
        ({
          Scenario scenario,
          bool hasDraft,
          bool publishedExists,
          bool remoteExists,
          bool remoteIsNewer,
        })
      >
    >.internal(
      scenarioListWithStatus,
      name: r'scenarioListWithStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scenarioListWithStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenarioListWithStatusRef =
    FutureProviderRef<
      List<
        ({
          Scenario scenario,
          bool hasDraft,
          bool publishedExists,
          bool remoteExists,
          bool remoteIsNewer,
        })
      >
    >;
String _$scenarioSyncServiceHash() =>
    r'5bb5316e66fc82c41e9d9508aac041be0c6a0198';

/// Returns a [ScenarioSyncService] when a server is configured, null otherwise.
/// Kept alive so the underlying [RemoteApiClient] is reused across calls.
///
/// Copied from [scenarioSyncService].
@ProviderFor(scenarioSyncService)
final scenarioSyncServiceProvider = Provider<ScenarioSyncService?>.internal(
  scenarioSyncService,
  name: r'scenarioSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scenarioSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenarioSyncServiceRef = ProviderRef<ScenarioSyncService?>;
String _$scenarioStartupSyncHash() =>
    r'a03465c223df262ae667fae458fa4cb41f684af1';

/// Fires a [ScenarioSyncService.pullAll] on first watch when a server is
/// configured, then invalidates the scenario list providers so the UI updates.
///
/// This is a fire-and-forget provider — the app shell watches it once at
/// startup. Returns null on success or when no server is configured;
/// the scenario list updates automatically via invalidation.
///
/// Copied from [scenarioStartupSync].
@ProviderFor(scenarioStartupSync)
final scenarioStartupSyncProvider = FutureProvider<void>.internal(
  scenarioStartupSync,
  name: r'scenarioStartupSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scenarioStartupSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenarioStartupSyncRef = FutureProviderRef<void>;
String _$scenarioByIdHash() => r'ed07158e28a21185ecce4fc219ae7627b898bd76';

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

/// See also [scenarioById].
@ProviderFor(scenarioById)
const scenarioByIdProvider = ScenarioByIdFamily();

/// See also [scenarioById].
class ScenarioByIdFamily extends Family<AsyncValue<Scenario?>> {
  /// See also [scenarioById].
  const ScenarioByIdFamily();

  /// See also [scenarioById].
  ScenarioByIdProvider call(String id, String version) {
    return ScenarioByIdProvider(id, version);
  }

  @override
  ScenarioByIdProvider getProviderOverride(
    covariant ScenarioByIdProvider provider,
  ) {
    return call(provider.id, provider.version);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'scenarioByIdProvider';
}

/// See also [scenarioById].
class ScenarioByIdProvider extends AutoDisposeFutureProvider<Scenario?> {
  /// See also [scenarioById].
  ScenarioByIdProvider(String id, String version)
    : this._internal(
        (ref) => scenarioById(ref as ScenarioByIdRef, id, version),
        from: scenarioByIdProvider,
        name: r'scenarioByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$scenarioByIdHash,
        dependencies: ScenarioByIdFamily._dependencies,
        allTransitiveDependencies:
            ScenarioByIdFamily._allTransitiveDependencies,
        id: id,
        version: version,
      );

  ScenarioByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
    required this.version,
  }) : super.internal();

  final String id;
  final String version;

  @override
  Override overrideWith(
    FutureOr<Scenario?> Function(ScenarioByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScenarioByIdProvider._internal(
        (ref) => create(ref as ScenarioByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
        version: version,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Scenario?> createElement() {
    return _ScenarioByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScenarioByIdProvider &&
        other.id == id &&
        other.version == version;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);
    hash = _SystemHash.combine(hash, version.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScenarioByIdRef on AutoDisposeFutureProviderRef<Scenario?> {
  /// The parameter `id` of this provider.
  String get id;

  /// The parameter `version` of this provider.
  String get version;
}

class _ScenarioByIdProviderElement
    extends AutoDisposeFutureProviderElement<Scenario?>
    with ScenarioByIdRef {
  _ScenarioByIdProviderElement(super.provider);

  @override
  String get id => (origin as ScenarioByIdProvider).id;
  @override
  String get version => (origin as ScenarioByIdProvider).version;
}

String _$scenarioForEditingHash() =>
    r'f7eea13751daac065ceb88b52aa14ec93db74bf1';

/// Loads a scenario for editing: returns the draft if one exists, otherwise
/// the published version. The bool indicates whether a draft was found.
///
/// Copied from [scenarioForEditing].
@ProviderFor(scenarioForEditing)
const scenarioForEditingProvider = ScenarioForEditingFamily();

/// Loads a scenario for editing: returns the draft if one exists, otherwise
/// the published version. The bool indicates whether a draft was found.
///
/// Copied from [scenarioForEditing].
class ScenarioForEditingFamily
    extends Family<AsyncValue<({Scenario scenario, bool hasDraft})>> {
  /// Loads a scenario for editing: returns the draft if one exists, otherwise
  /// the published version. The bool indicates whether a draft was found.
  ///
  /// Copied from [scenarioForEditing].
  const ScenarioForEditingFamily();

  /// Loads a scenario for editing: returns the draft if one exists, otherwise
  /// the published version. The bool indicates whether a draft was found.
  ///
  /// Copied from [scenarioForEditing].
  ScenarioForEditingProvider call(String id, String version) {
    return ScenarioForEditingProvider(id, version);
  }

  @override
  ScenarioForEditingProvider getProviderOverride(
    covariant ScenarioForEditingProvider provider,
  ) {
    return call(provider.id, provider.version);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'scenarioForEditingProvider';
}

/// Loads a scenario for editing: returns the draft if one exists, otherwise
/// the published version. The bool indicates whether a draft was found.
///
/// Copied from [scenarioForEditing].
class ScenarioForEditingProvider
    extends AutoDisposeFutureProvider<({Scenario scenario, bool hasDraft})> {
  /// Loads a scenario for editing: returns the draft if one exists, otherwise
  /// the published version. The bool indicates whether a draft was found.
  ///
  /// Copied from [scenarioForEditing].
  ScenarioForEditingProvider(String id, String version)
    : this._internal(
        (ref) => scenarioForEditing(ref as ScenarioForEditingRef, id, version),
        from: scenarioForEditingProvider,
        name: r'scenarioForEditingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$scenarioForEditingHash,
        dependencies: ScenarioForEditingFamily._dependencies,
        allTransitiveDependencies:
            ScenarioForEditingFamily._allTransitiveDependencies,
        id: id,
        version: version,
      );

  ScenarioForEditingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
    required this.version,
  }) : super.internal();

  final String id;
  final String version;

  @override
  Override overrideWith(
    FutureOr<({Scenario scenario, bool hasDraft})> Function(
      ScenarioForEditingRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScenarioForEditingProvider._internal(
        (ref) => create(ref as ScenarioForEditingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
        version: version,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<({Scenario scenario, bool hasDraft})>
  createElement() {
    return _ScenarioForEditingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScenarioForEditingProvider &&
        other.id == id &&
        other.version == version;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);
    hash = _SystemHash.combine(hash, version.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScenarioForEditingRef
    on AutoDisposeFutureProviderRef<({Scenario scenario, bool hasDraft})> {
  /// The parameter `id` of this provider.
  String get id;

  /// The parameter `version` of this provider.
  String get version;
}

class _ScenarioForEditingProviderElement
    extends
        AutoDisposeFutureProviderElement<({Scenario scenario, bool hasDraft})>
    with ScenarioForEditingRef {
  _ScenarioForEditingProviderElement(super.provider);

  @override
  String get id => (origin as ScenarioForEditingProvider).id;
  @override
  String get version => (origin as ScenarioForEditingProvider).version;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
