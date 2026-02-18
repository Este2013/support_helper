/// Sealed union representing where an answer routes to.
/// Serialized with a "type" discriminator field.
sealed class AnswerDestination {
  const AnswerDestination();

  factory AnswerDestination.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'question' => DestinationQuestion.fromJson(json),
      'end' => const DestinationEnd(),
      'end_with_notes' => DestinationEndWithNotes.fromJson(json),
      'subflow' => DestinationSubFlow.fromJson(json),
      _ => throw ArgumentError('Unknown AnswerDestination type: $type'),
    };
  }

  Map<String, dynamic> toJson();
}

class DestinationQuestion extends AnswerDestination {
  final String questionId;

  const DestinationQuestion({required this.questionId});

  factory DestinationQuestion.fromJson(Map<String, dynamic> json) =>
      DestinationQuestion(questionId: json['questionId'] as String);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'question',
        'questionId': questionId,
      };

  DestinationQuestion copyWith({String? questionId}) =>
      DestinationQuestion(questionId: questionId ?? this.questionId);
}

class DestinationEnd extends AnswerDestination {
  const DestinationEnd();

  factory DestinationEnd.fromJson(Map<String, dynamic> json) =>
      const DestinationEnd();

  @override
  Map<String, dynamic> toJson() => {'type': 'end'};
}

class DestinationSubFlow extends AnswerDestination {
  final String firstQuestionId;
  final String resumeQuestionId;

  const DestinationSubFlow({
    required this.firstQuestionId,
    required this.resumeQuestionId,
  });

  factory DestinationSubFlow.fromJson(Map<String, dynamic> json) =>
      DestinationSubFlow(
        firstQuestionId: json['firstQuestionId'] as String,
        resumeQuestionId: json['resumeQuestionId'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'subflow',
        'firstQuestionId': firstQuestionId,
        'resumeQuestionId': resumeQuestionId,
      };

  DestinationSubFlow copyWith({
    String? firstQuestionId,
    String? resumeQuestionId,
  }) =>
      DestinationSubFlow(
        firstQuestionId: firstQuestionId ?? this.firstQuestionId,
        resumeQuestionId: resumeQuestionId ?? this.resumeQuestionId,
      );
}

/// End the scenario (or pop a sub-flow frame) and display custom markdown notes.
class DestinationEndWithNotes extends AnswerDestination {
  final String notes;

  const DestinationEndWithNotes({required this.notes});

  factory DestinationEndWithNotes.fromJson(Map<String, dynamic> json) =>
      DestinationEndWithNotes(notes: json['notes'] as String? ?? '');

  @override
  Map<String, dynamic> toJson() => {
        'type': 'end_with_notes',
        'notes': notes,
      };

  DestinationEndWithNotes copyWith({String? notes}) =>
      DestinationEndWithNotes(notes: notes ?? this.notes);
}
