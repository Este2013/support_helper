class SessionHistoryEntry {
  final String questionId;
  final String questionTitle;
  final String answerLabel;
  final DateTime answeredAt;
  /// Snapshot of subFlowStack (list of resumeQuestionIds) at the time of answering.
  /// Used to restore sub-flow state correctly when going back.
  final List<String> subFlowStackSnapshot;

  const SessionHistoryEntry({
    required this.questionId,
    required this.questionTitle,
    required this.answerLabel,
    required this.answeredAt,
    this.subFlowStackSnapshot = const [],
  });

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SessionHistoryEntry(
        questionId: json['questionId'] as String,
        questionTitle: json['questionTitle'] as String,
        answerLabel: json['answerLabel'] as String,
        answeredAt: DateTime.parse(json['answeredAt'] as String),
        subFlowStackSnapshot:
            (json['subFlowStackSnapshot'] as List<dynamic>? ?? [])
                .cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionTitle': questionTitle,
        'answerLabel': answerLabel,
        'answeredAt': answeredAt.toIso8601String(),
        'subFlowStackSnapshot': subFlowStackSnapshot,
      };
}
