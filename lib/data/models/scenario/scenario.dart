import 'question.dart';

/// Whether this scenario was created locally or pulled from a remote server.
/// Stored in the JSON file so the origin is known across restarts.
/// Old files without a [source] key default to [ScenarioSource.local].
enum ScenarioSource { local, remote }

class Scenario {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Origin of this scenario. Defaults to [ScenarioSource.local] for all
  /// existing files (backward-compatible — missing key → 'local').
  final ScenarioSource source;

  const Scenario({
    required this.id,
    required this.name,
    this.description = '',
    required this.version,
    this.author = '',
    this.questions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.source = ScenarioSource.local,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        version: json['version'] as String,
        author: json['author'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        source: ScenarioSource.values.byName(
          json['source'] as String? ?? ScenarioSource.local.name,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'version': version,
        'author': author,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'source': source.name,
      };

  Scenario copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? author,
    List<Question>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
    ScenarioSource? source,
  }) =>
      Scenario(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        version: version ?? this.version,
        author: author ?? this.author,
        questions: questions ?? this.questions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        source: source ?? this.source,
      );

  /// Returns null if scenario is valid, otherwise an error message.
  String? validate() {
    if (id.trim().isEmpty) return 'Scenario ID cannot be empty';
    if (name.trim().isEmpty) return 'Scenario name cannot be empty';
    final ids = questions.map((q) => q.id).toList();
    if (ids.length != ids.toSet().length) return 'Duplicate question IDs found';
    return null;
  }

  /// Filename-safe key combining id + version
  String get fileKey => '${id}_v$version';

  /// Find a question by id
  Question? questionById(String id) {
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}
