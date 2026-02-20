// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSessionHash() => r'1bd6410b65cabdec755665d61116f7b43b94c5a7';

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

abstract class _$ActiveSession
    extends BuildlessAutoDisposeNotifier<ScenarioSession?> {
  late final String profileId;
  late final String sessionId;

  ScenarioSession? build(String profileId, String sessionId);
}

/// See also [ActiveSession].
@ProviderFor(ActiveSession)
const activeSessionProvider = ActiveSessionFamily();

/// See also [ActiveSession].
class ActiveSessionFamily extends Family<ScenarioSession?> {
  /// See also [ActiveSession].
  const ActiveSessionFamily();

  /// See also [ActiveSession].
  ActiveSessionProvider call(String profileId, String sessionId) {
    return ActiveSessionProvider(profileId, sessionId);
  }

  @override
  ActiveSessionProvider getProviderOverride(
    covariant ActiveSessionProvider provider,
  ) {
    return call(provider.profileId, provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'activeSessionProvider';
}

/// See also [ActiveSession].
class ActiveSessionProvider
    extends AutoDisposeNotifierProviderImpl<ActiveSession, ScenarioSession?> {
  /// See also [ActiveSession].
  ActiveSessionProvider(String profileId, String sessionId)
    : this._internal(
        () => ActiveSession()
          ..profileId = profileId
          ..sessionId = sessionId,
        from: activeSessionProvider,
        name: r'activeSessionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$activeSessionHash,
        dependencies: ActiveSessionFamily._dependencies,
        allTransitiveDependencies:
            ActiveSessionFamily._allTransitiveDependencies,
        profileId: profileId,
        sessionId: sessionId,
      );

  ActiveSessionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
    required this.sessionId,
  }) : super.internal();

  final String profileId;
  final String sessionId;

  @override
  ScenarioSession? runNotifierBuild(covariant ActiveSession notifier) {
    return notifier.build(profileId, sessionId);
  }

  @override
  Override overrideWith(ActiveSession Function() create) {
    return ProviderOverride(
      origin: this,
      override: ActiveSessionProvider._internal(
        () => create()
          ..profileId = profileId
          ..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ActiveSession, ScenarioSession?>
  createElement() {
    return _ActiveSessionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSessionProvider &&
        other.profileId == profileId &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActiveSessionRef on AutoDisposeNotifierProviderRef<ScenarioSession?> {
  /// The parameter `profileId` of this provider.
  String get profileId;

  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _ActiveSessionProviderElement
    extends AutoDisposeNotifierProviderElement<ActiveSession, ScenarioSession?>
    with ActiveSessionRef {
  _ActiveSessionProviderElement(super.provider);

  @override
  String get profileId => (origin as ActiveSessionProvider).profileId;
  @override
  String get sessionId => (origin as ActiveSessionProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
