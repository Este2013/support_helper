import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/profile/scenario_session.dart';
import '../data/models/profile/session_history_entry.dart';
import '../data/models/scenario/answer_destination.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_providers.dart';

part 'session_providers.g.dart';

@riverpod
class ActiveSession extends _$ActiveSession {
  @override
  ScenarioSession? build(String profileId, String sessionId) {
    // Load from profile cache
    final profileAsync = ref.watch(profileByIdProvider(profileId));
    return profileAsync.whenOrNull(
      data: (profile) => profile?.sessionById(sessionId),
    );
  }

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> chooseAnswer(
    String answerLabel,
    String questionTitle,
    AnswerDestination destination,
  ) async {
    final session = state;
    if (session == null || session.status == SessionStatus.completed) return;

    // Build history entry with current subflow stack snapshot
    final historyEntry = SessionHistoryEntry(
      questionId: session.currentQuestionId,
      questionTitle: questionTitle,
      answerLabel: answerLabel,
      answeredAt: DateTime.now(),
      subFlowStackSnapshot: List.unmodifiable(session.subFlowStack),
    );

    // Update storedAnswers
    final storedAnswers = Map<String, String>.from(session.storedAnswers);
    storedAnswers[session.currentQuestionId] = answerLabel;

    final history = [...session.history, historyEntry];

    String nextQuestionId = session.currentQuestionId;
    List<String> subFlowStack = List<String>.from(session.subFlowStack);
    SessionStatus status = session.status;
    String? completionNotes;

    switch (destination) {
      case DestinationQuestion d:
        nextQuestionId = d.questionId;
      case DestinationSubFlow d:
        subFlowStack.add(d.resumeQuestionId);
        nextQuestionId = d.firstQuestionId;
      case DestinationEnd _:
        if (subFlowStack.isEmpty) {
          status = SessionStatus.completed;
        } else {
          nextQuestionId = subFlowStack.removeLast();
        }
      case DestinationEndWithNotes d:
        if (subFlowStack.isEmpty) {
          status = SessionStatus.completed;
          completionNotes = d.notes;
        } else {
          nextQuestionId = subFlowStack.removeLast();
        }
    }

    final updated = session.copyWith(
      currentQuestionId: nextQuestionId,
      history: history,
      storedAnswers: storedAnswers,
      subFlowStack: subFlowStack,
      status: status,
      completionNotes: completionNotes,
      updatedAt: DateTime.now(),
    );

    state = updated;
    await _persist(updated);
    ref.invalidate(profileByIdProvider(profileId));
  }

  Future<void> goBack() async {
    final session = state;
    if (session == null || session.history.isEmpty) return;

    final history = List<SessionHistoryEntry>.from(session.history);
    final last = history.removeLast();

    // Remove stored answer for the question we're going back to
    final storedAnswers = Map<String, String>.from(session.storedAnswers);
    storedAnswers.remove(last.questionId);

    // Restore subflow stack from snapshot
    final subFlowStack = List<String>.from(last.subFlowStackSnapshot);

    final updated = session.copyWith(
      currentQuestionId: last.questionId,
      history: history,
      storedAnswers: storedAnswers,
      subFlowStack: subFlowStack,
      status: SessionStatus.inProgress,
      updatedAt: DateTime.now(),
    );

    state = updated;
    await _persist(updated);
    ref.invalidate(profileByIdProvider(profileId));
  }

  Future<void> markCompleted() async {
    final session = state;
    if (session == null) return;
    final updated = session.copyWith(
      status: SessionStatus.completed,
      updatedAt: DateTime.now(),
    );
    state = updated;
    await _persist(updated);
    ref.invalidate(profileByIdProvider(profileId));
  }

  Future<void> _persist(ScenarioSession session) async {
    await _repo.upsertSession(profileId, session);
  }
}
