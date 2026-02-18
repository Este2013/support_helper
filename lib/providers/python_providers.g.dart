// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'python_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pythonRunnerHash() => r'480dae4a20c138f66be945a4a99e81923f933ddc';

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

abstract class _$PythonRunner
    extends BuildlessAutoDisposeNotifier<PythonRunState> {
  late final String profileId;
  late final String sessionId;
  late final String questionId;

  PythonRunState build(String profileId, String sessionId, String questionId);
}

/// See also [PythonRunner].
@ProviderFor(PythonRunner)
const pythonRunnerProvider = PythonRunnerFamily();

/// See also [PythonRunner].
class PythonRunnerFamily extends Family<PythonRunState> {
  /// See also [PythonRunner].
  const PythonRunnerFamily();

  /// See also [PythonRunner].
  PythonRunnerProvider call(
    String profileId,
    String sessionId,
    String questionId,
  ) {
    return PythonRunnerProvider(profileId, sessionId, questionId);
  }

  @override
  PythonRunnerProvider getProviderOverride(
    covariant PythonRunnerProvider provider,
  ) {
    return call(provider.profileId, provider.sessionId, provider.questionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pythonRunnerProvider';
}

/// See also [PythonRunner].
class PythonRunnerProvider
    extends AutoDisposeNotifierProviderImpl<PythonRunner, PythonRunState> {
  /// See also [PythonRunner].
  PythonRunnerProvider(String profileId, String sessionId, String questionId)
    : this._internal(
        () => PythonRunner()
          ..profileId = profileId
          ..sessionId = sessionId
          ..questionId = questionId,
        from: pythonRunnerProvider,
        name: r'pythonRunnerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$pythonRunnerHash,
        dependencies: PythonRunnerFamily._dependencies,
        allTransitiveDependencies:
            PythonRunnerFamily._allTransitiveDependencies,
        profileId: profileId,
        sessionId: sessionId,
        questionId: questionId,
      );

  PythonRunnerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
    required this.sessionId,
    required this.questionId,
  }) : super.internal();

  final String profileId;
  final String sessionId;
  final String questionId;

  @override
  PythonRunState runNotifierBuild(covariant PythonRunner notifier) {
    return notifier.build(profileId, sessionId, questionId);
  }

  @override
  Override overrideWith(PythonRunner Function() create) {
    return ProviderOverride(
      origin: this,
      override: PythonRunnerProvider._internal(
        () => create()
          ..profileId = profileId
          ..sessionId = sessionId
          ..questionId = questionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
        sessionId: sessionId,
        questionId: questionId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<PythonRunner, PythonRunState>
  createElement() {
    return _PythonRunnerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PythonRunnerProvider &&
        other.profileId == profileId &&
        other.sessionId == sessionId &&
        other.questionId == questionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);
    hash = _SystemHash.combine(hash, questionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PythonRunnerRef on AutoDisposeNotifierProviderRef<PythonRunState> {
  /// The parameter `profileId` of this provider.
  String get profileId;

  /// The parameter `sessionId` of this provider.
  String get sessionId;

  /// The parameter `questionId` of this provider.
  String get questionId;
}

class _PythonRunnerProviderElement
    extends AutoDisposeNotifierProviderElement<PythonRunner, PythonRunState>
    with PythonRunnerRef {
  _PythonRunnerProviderElement(super.provider);

  @override
  String get profileId => (origin as PythonRunnerProvider).profileId;
  @override
  String get sessionId => (origin as PythonRunnerProvider).sessionId;
  @override
  String get questionId => (origin as PythonRunnerProvider).questionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
