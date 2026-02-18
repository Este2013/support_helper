import 'answer.dart';
import 'external_link.dart';

class Question {
  final String id;
  final String title;
  final String notes;
  final String? pythonScriptPath;
  final List<Answer> answers;
  final List<ExternalLink> externalLinks;
  /// Editor-only: folder label used for grouping questions in the editor UI.
  /// Has no effect on scenario playback.
  final String folder;

  const Question({
    required this.id,
    required this.title,
    this.notes = '',
    this.pythonScriptPath,
    this.answers = const [],
    this.externalLinks = const [],
    this.folder = '',
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
        folder: json['folder'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        if (pythonScriptPath != null) 'pythonScriptPath': pythonScriptPath,
        'answers': answers.map((a) => a.toJson()).toList(),
        'externalLinks': externalLinks.map((l) => l.toJson()).toList(),
        if (folder.isNotEmpty) 'folder': folder,
      };

  Question copyWith({
    String? id,
    String? title,
    String? notes,
    String? pythonScriptPath,
    List<Answer>? answers,
    List<ExternalLink>? externalLinks,
    bool clearPythonScript = false,
    String? folder,
  }) =>
      Question(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        pythonScriptPath:
            clearPythonScript ? null : (pythonScriptPath ?? this.pythonScriptPath),
        answers: answers ?? this.answers,
        externalLinks: externalLinks ?? this.externalLinks,
        folder: folder ?? this.folder,
      );
}
