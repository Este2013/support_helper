import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/scenario/scenario.dart';
import '../data/models/scenario/question.dart';
import '../data/models/scenario/answer.dart';
import '../data/models/scenario/external_link.dart';
import '../data/repositories/scenario_repository.dart';
import 'scenario_providers.dart';

part 'editor_providers.g.dart';

class ScenarioEditorState {
  final Scenario draft;
  final bool isDirty;
  final String? validationError;
  final bool isSaving;

  const ScenarioEditorState({
    required this.draft,
    this.isDirty = false,
    this.validationError,
    this.isSaving = false,
  });

  ScenarioEditorState copyWith({
    Scenario? draft,
    bool? isDirty,
    String? validationError,
    bool clearValidationError = false,
    bool? isSaving,
  }) =>
      ScenarioEditorState(
        draft: draft ?? this.draft,
        isDirty: isDirty ?? this.isDirty,
        validationError:
            clearValidationError ? null : (validationError ?? this.validationError),
        isSaving: isSaving ?? this.isSaving,
      );
}

@riverpod
class ScenarioEditor extends _$ScenarioEditor {
  @override
  ScenarioEditorState build(Scenario initialScenario) {
    return ScenarioEditorState(draft: initialScenario);
  }

  ScenarioRepository get _repo => ref.read(scenarioRepositoryProvider);

  void updateMeta({
    String? id,
    String? name,
    String? description,
    String? version,
    String? author,
  }) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        id: id,
        name: name,
        description: description,
        version: version,
        author: author,
        updatedAt: DateTime.now(),
      ),
      isDirty: true,
      clearValidationError: true,
    );
  }

  void addQuestion(Question q) {
    final questions = [...state.draft.questions, q];
    state = state.copyWith(
      draft: state.draft.copyWith(questions: questions, updatedAt: DateTime.now()),
      isDirty: true,
    );
  }

  void updateQuestion(String questionId, Question updated) {
    final questions = [
      for (final q in state.draft.questions)
        if (q.id == questionId) updated else q,
    ];
    state = state.copyWith(
      draft: state.draft.copyWith(questions: questions, updatedAt: DateTime.now()),
      isDirty: true,
    );
  }

  void deleteQuestion(String questionId) {
    final questions =
        state.draft.questions.where((q) => q.id != questionId).toList();
    state = state.copyWith(
      draft: state.draft.copyWith(questions: questions, updatedAt: DateTime.now()),
      isDirty: true,
    );
  }

  void reorderQuestions(int oldIndex, int newIndex) {
    final questions = List<Question>.from(state.draft.questions);
    final item = questions.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    questions.insert(insertAt, item);
    state = state.copyWith(
      draft: state.draft.copyWith(questions: questions, updatedAt: DateTime.now()),
      isDirty: true,
    );
  }

  void addAnswer(String questionId, Answer answer) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    updateQuestion(questionId, q.copyWith(answers: [...q.answers, answer]));
  }

  void updateAnswer(String questionId, int index, Answer answer) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    final answers = List<Answer>.from(q.answers);
    answers[index] = answer;
    updateQuestion(questionId, q.copyWith(answers: answers));
  }

  void deleteAnswer(String questionId, int index) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    final answers = List<Answer>.from(q.answers)..removeAt(index);
    updateQuestion(questionId, q.copyWith(answers: answers));
  }

  void reorderAnswers(String questionId, int oldIndex, int newIndex) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    final answers = List<Answer>.from(q.answers);
    final item = answers.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    answers.insert(insertAt, item);
    updateQuestion(questionId, q.copyWith(answers: answers));
  }

  void addExternalLink(String questionId, ExternalLink link) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    updateQuestion(questionId, q.copyWith(externalLinks: [...q.externalLinks, link]));
  }

  void removeExternalLink(String questionId, int index) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    final links = List<ExternalLink>.from(q.externalLinks)..removeAt(index);
    updateQuestion(questionId, q.copyWith(externalLinks: links));
  }

  Future<bool> save() async {
    final error = state.draft.validate();
    if (error != null) {
      state = state.copyWith(validationError: error);
      return false;
    }
    state = state.copyWith(isSaving: true);
    try {
      await _repo.save(state.draft);
      ref.invalidate(scenarioListProvider);
      state = state.copyWith(isDirty: false, isSaving: false, clearValidationError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          validationError: 'Save failed: $e', isSaving: false);
      return false;
    }
  }
}
