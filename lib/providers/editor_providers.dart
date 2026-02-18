import 'dart:async';
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
  /// True while the background draft file is being written.
  final bool isDraftSaving;

  const ScenarioEditorState({
    required this.draft,
    this.isDirty = false,
    this.validationError,
    this.isSaving = false,
    this.isDraftSaving = false,
  });

  ScenarioEditorState copyWith({
    Scenario? draft,
    bool? isDirty,
    String? validationError,
    bool clearValidationError = false,
    bool? isSaving,
    bool? isDraftSaving,
  }) =>
      ScenarioEditorState(
        draft: draft ?? this.draft,
        isDirty: isDirty ?? this.isDirty,
        validationError: clearValidationError
            ? null
            : (validationError ?? this.validationError),
        isSaving: isSaving ?? this.isSaving,
        isDraftSaving: isDraftSaving ?? this.isDraftSaving,
      );
}

@riverpod
class ScenarioEditor extends _$ScenarioEditor {
  /// Debounce timer for auto-saving the draft file.
  Timer? _draftTimer;

  /// The id+version under which the draft was last successfully written.
  /// Used to detect when the scenario id/version has been renamed between
  /// debounce ticks so we can delete the old draft file instead of leaving
  /// orphans behind.
  String? _lastDraftId;
  String? _lastDraftVersion;

  @override
  ScenarioEditorState build(Scenario initialScenario) {
    // Cancel any pending draft write when the provider is disposed.
    ref.onDispose(() => _draftTimer?.cancel());
    // Seed the "last known" identity from the scenario we opened with.
    _lastDraftId = initialScenario.id;
    _lastDraftVersion = initialScenario.version;
    return ScenarioEditorState(draft: initialScenario);
  }

  ScenarioRepository get _repo => ref.read(scenarioRepositoryProvider);

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Marks the draft dirty and schedules a debounced draft file write.
  void _markDirty(Scenario newDraft) {
    state = state.copyWith(
      draft: newDraft,
      isDirty: true,
      clearValidationError: true,
    );
    _scheduleDraftSave();
  }

  /// Debounces draft persistence: waits 800 ms after the last change.
  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _writeDraft);
  }

  Future<void> _writeDraft() async {
    state = state.copyWith(isDraftSaving: true);
    final current = state.draft;
    try {
      // If the scenario id or version changed since the last write, delete
      // the old draft file first — otherwise we accumulate one orphan per
      // keystroke as the user edits the ID field.
      final idChanged = _lastDraftId != null && _lastDraftId != current.id;
      final versionChanged =
          _lastDraftVersion != null && _lastDraftVersion != current.version;
      if (idChanged || versionChanged) {
        await _repo.deleteDraft(_lastDraftId!, _lastDraftVersion!);
      }
      await _repo.saveDraft(current);
      _lastDraftId = current.id;
      _lastDraftVersion = current.version;
    } finally {
      state = state.copyWith(isDraftSaving: false);
    }
  }

  // ── Called by _EditorBody when a draft was loaded on open ─────────────────

  /// Marks the state dirty without touching the draft file — used when the
  /// editor was opened and a pre-existing draft was loaded as the initial state.
  void markDirtyFromDraft() {
    if (state.isDirty) return; // already dirty, nothing to do
    state = state.copyWith(isDirty: true);
  }

  // ── Public mutation API ────────────────────────────────────────────────────

  void updateMeta({
    String? id,
    String? name,
    String? description,
    String? version,
    String? author,
  }) {
    _markDirty(state.draft.copyWith(
      id: id,
      name: name,
      description: description,
      version: version,
      author: author,
      updatedAt: DateTime.now(),
    ));
  }

  void addQuestion(Question q) {
    _markDirty(state.draft.copyWith(
      questions: [...state.draft.questions, q],
      updatedAt: DateTime.now(),
    ));
  }

  void updateQuestion(String questionId, Question updated) {
    _markDirty(state.draft.copyWith(
      questions: [
        for (final q in state.draft.questions)
          if (q.id == questionId) updated else q,
      ],
      updatedAt: DateTime.now(),
    ));
  }

  void deleteQuestion(String questionId) {
    _markDirty(state.draft.copyWith(
      questions: state.draft.questions.where((q) => q.id != questionId).toList(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Move a question to a different folder (or '' to remove from all folders).
  void moveQuestionToFolder(String questionId, String folder) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    updateQuestion(questionId, q.copyWith(folder: folder));
  }

  /// Rename every question whose folder == oldName to newName.
  void renameFolder(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed == oldName) return;
    _markDirty(state.draft.copyWith(
      questions: [
        for (final q in state.draft.questions)
          if (q.folder == oldName) q.copyWith(folder: trimmed) else q,
      ],
      updatedAt: DateTime.now(),
    ));
  }

  /// Delete a folder — moves all its questions to the root folder ('').
  void deleteFolder(String name) => renameFolder(name, '');

  void reorderQuestions(int oldIndex, int newIndex) {
    final questions = List<Question>.from(state.draft.questions);
    final item = questions.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    questions.insert(insertAt, item);
    _markDirty(state.draft.copyWith(
      questions: questions,
      updatedAt: DateTime.now(),
    ));
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
    updateQuestion(
        questionId,
        q.copyWith(
            answers: List<Answer>.from(q.answers)..removeAt(index)));
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
    updateQuestion(questionId,
        q.copyWith(externalLinks: [...q.externalLinks, link]));
  }

  void removeExternalLink(String questionId, int index) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    updateQuestion(
        questionId,
        q.copyWith(
            externalLinks: List<ExternalLink>.from(q.externalLinks)
              ..removeAt(index)));
  }

  // ── Publish (Save button) ──────────────────────────────────────────────────

  Future<bool> save() async {
    // Cancel any pending debounced draft write.
    _draftTimer?.cancel();
    _draftTimer = null;

    final error = state.draft.validate();
    if (error != null) {
      state = state.copyWith(validationError: error);
      return false;
    }
    state = state.copyWith(isSaving: true);
    try {
      // If the id/version was renamed while the timer was pending, the old
      // draft file still exists under _lastDraftId/_lastDraftVersion —
      // delete it before publishing so no orphan is left behind.
      final current = state.draft;
      if (_lastDraftId != null &&
          (_lastDraftId != current.id ||
              _lastDraftVersion != current.version)) {
        await _repo.deleteDraft(_lastDraftId!, _lastDraftVersion!);
      }
      // repo.save() writes the published file and deletes the draft at the
      // current id/version.
      await _repo.save(current);
      _lastDraftId = current.id;
      _lastDraftVersion = current.version;
      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);
      state = state.copyWith(
        isDirty: false,
        isSaving: false,
        clearValidationError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          validationError: 'Save failed: $e', isSaving: false);
      return false;
    }
  }
}
