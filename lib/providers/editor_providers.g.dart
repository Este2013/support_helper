// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scenarioEditorHash() => r'674b5409724c85e592ee5cae92cbc35a689ba9f7';

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

abstract class _$ScenarioEditor
    extends BuildlessAutoDisposeNotifier<ScenarioEditorState> {
  late final Scenario initialScenario;

  ScenarioEditorState build(Scenario initialScenario);
}

/// See also [ScenarioEditor].
@ProviderFor(ScenarioEditor)
const scenarioEditorProvider = ScenarioEditorFamily();

/// See also [ScenarioEditor].
class ScenarioEditorFamily extends Family<ScenarioEditorState> {
  /// See also [ScenarioEditor].
  const ScenarioEditorFamily();

  /// See also [ScenarioEditor].
  ScenarioEditorProvider call(Scenario initialScenario) {
    return ScenarioEditorProvider(initialScenario);
  }

  @override
  ScenarioEditorProvider getProviderOverride(
    covariant ScenarioEditorProvider provider,
  ) {
    return call(provider.initialScenario);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'scenarioEditorProvider';
}

/// See also [ScenarioEditor].
class ScenarioEditorProvider
    extends
        AutoDisposeNotifierProviderImpl<ScenarioEditor, ScenarioEditorState> {
  /// See also [ScenarioEditor].
  ScenarioEditorProvider(Scenario initialScenario)
    : this._internal(
        () => ScenarioEditor()..initialScenario = initialScenario,
        from: scenarioEditorProvider,
        name: r'scenarioEditorProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$scenarioEditorHash,
        dependencies: ScenarioEditorFamily._dependencies,
        allTransitiveDependencies:
            ScenarioEditorFamily._allTransitiveDependencies,
        initialScenario: initialScenario,
      );

  ScenarioEditorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialScenario,
  }) : super.internal();

  final Scenario initialScenario;

  @override
  ScenarioEditorState runNotifierBuild(covariant ScenarioEditor notifier) {
    return notifier.build(initialScenario);
  }

  @override
  Override overrideWith(ScenarioEditor Function() create) {
    return ProviderOverride(
      origin: this,
      override: ScenarioEditorProvider._internal(
        () => create()..initialScenario = initialScenario,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialScenario: initialScenario,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ScenarioEditor, ScenarioEditorState>
  createElement() {
    return _ScenarioEditorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScenarioEditorProvider &&
        other.initialScenario == initialScenario;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialScenario.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScenarioEditorRef on AutoDisposeNotifierProviderRef<ScenarioEditorState> {
  /// The parameter `initialScenario` of this provider.
  Scenario get initialScenario;
}

class _ScenarioEditorProviderElement
    extends
        AutoDisposeNotifierProviderElement<ScenarioEditor, ScenarioEditorState>
    with ScenarioEditorRef {
  _ScenarioEditorProviderElement(super.provider);

  @override
  Scenario get initialScenario =>
      (origin as ScenarioEditorProvider).initialScenario;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
