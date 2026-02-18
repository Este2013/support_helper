// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scenarioRepositoryHash() =>
    r'3e740391d88d3b6a517d99c2c366f88a883c6ca7';

/// See also [scenarioRepository].
@ProviderFor(scenarioRepository)
final scenarioRepositoryProvider = Provider<ScenarioRepository>.internal(
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
typedef ScenarioRepositoryRef = ProviderRef<ScenarioRepository>;
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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
