import 'session_history_entry.dart';

enum SessionStatus { inProgress, completed }

class ScenarioSession {
  final String id;
  final String scenarioId;
  final String scenarioVersion;
  final String scenarioName;
  final SessionStatus status;
  final String currentQuestionId;
  final List<SessionHistoryEntry> history;
  final Map<String, String> storedAnswers;
  /// Stack of sub-flow resumeQuestionIds. Last element is the current sub-flow's resume point.
  final List<String> subFlowStack;
  /// Optional markdown notes shown on the custom end screen (from DestinationEndWithNotes).
  final String? completionNotes;
  final DateTime startedAt;
  final DateTime updatedAt;

  const ScenarioSession({
    required this.id,
    required this.scenarioId,
    required this.scenarioVersion,
    required this.scenarioName,
    this.status = SessionStatus.inProgress,
    required this.currentQuestionId,
    this.history = const [],
    this.storedAnswers = const {},
    this.subFlowStack = const [],
    this.completionNotes,
    required this.startedAt,
    required this.updatedAt,
  });

  factory ScenarioSession.fromJson(Map<String, dynamic> json) =>
      ScenarioSession(
        id: json['id'] as String,
        scenarioId: json['scenarioId'] as String,
        scenarioVersion: json['scenarioVersion'] as String,
        scenarioName: json['scenarioName'] as String,
        status: SessionStatus.values.byName(json['status'] as String),
        currentQuestionId: json['currentQuestionId'] as String,
        history: (json['history'] as List<dynamic>? ?? [])
            .map((e) =>
                SessionHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        storedAnswers: Map<String, String>.from(
            json['storedAnswers'] as Map<String, dynamic>? ?? {}),
        subFlowStack:
            (json['subFlowStack'] as List<dynamic>? ?? []).cast<String>(),
        completionNotes: json['completionNotes'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scenarioId': scenarioId,
        'scenarioVersion': scenarioVersion,
        'scenarioName': scenarioName,
        'status': status.name,
        'currentQuestionId': currentQuestionId,
        'history': history.map((e) => e.toJson()).toList(),
        'storedAnswers': storedAnswers,
        'subFlowStack': subFlowStack,
        if (completionNotes != null) 'completionNotes': completionNotes,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ScenarioSession copyWith({
    String? id,
    String? scenarioId,
    String? scenarioVersion,
    String? scenarioName,
    SessionStatus? status,
    String? currentQuestionId,
    List<SessionHistoryEntry>? history,
    Map<String, String>? storedAnswers,
    List<String>? subFlowStack,
    String? completionNotes,
    bool clearCompletionNotes = false,
    DateTime? startedAt,
    DateTime? updatedAt,
  }) =>
      ScenarioSession(
        id: id ?? this.id,
        scenarioId: scenarioId ?? this.scenarioId,
        scenarioVersion: scenarioVersion ?? this.scenarioVersion,
        scenarioName: scenarioName ?? this.scenarioName,
        status: status ?? this.status,
        currentQuestionId: currentQuestionId ?? this.currentQuestionId,
        history: history ?? this.history,
        storedAnswers: storedAnswers ?? this.storedAnswers,
        subFlowStack: subFlowStack ?? this.subFlowStack,
        completionNotes: clearCompletionNotes
            ? null
            : (completionNotes ?? this.completionNotes),
        startedAt: startedAt ?? this.startedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
