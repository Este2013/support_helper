import 'answer.dart';
import 'external_link.dart';

class Question {
  final String id;
  final String title;
  final String notes;
  final String? pythonScriptPath;
  final List<Answer> answers;
  final List<ExternalLink> externalLinks;

  const Question({
    required this.id,
    required this.title,
    this.notes = '',
    this.pythonScriptPath,
    this.answers = const [],
    this.externalLinks = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        pythonScriptPath: json['pythonScriptPath'] as String?,
        answers: (json['answers'] as List<dynamic>? ?? [])
            .map((e) => Answer.fromJson(e as Map<String, dynamic>))
            .toList(),
        externalLinks: (json['externalLinks'] as List<dynamic>? ?? [])
            .map((e) => ExternalLink.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        if (pythonScriptPath != null) 'pythonScriptPath': pythonScriptPath,
        'answers': answers.map((a) => a.toJson()).toList(),
        'externalLinks': externalLinks.map((l) => l.toJson()).toList(),
      };

  Question copyWith({
    String? id,
    String? title,
    String? notes,
    String? pythonScriptPath,
    List<Answer>? answers,
    List<ExternalLink>? externalLinks,
    bool clearPythonScript = false,
  }) =>
      Question(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        pythonScriptPath:
            clearPythonScript ? null : (pythonScriptPath ?? this.pythonScriptPath),
        answers: answers ?? this.answers,
        externalLinks: externalLinks ?? this.externalLinks,
      );
}
