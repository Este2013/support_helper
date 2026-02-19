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

  /// Whether the patch version has already been bumped this session.
  /// Prevents double-bumping on subsequent edits.
  bool _versionBumped = false;

  @override
  ScenarioEditorState build(Scenario initialScenario) {
    // Cancel any pending draft write when the provider is disposed.
    ref.onDispose(() => _draftTimer?.cancel());
    // If we opened with a draft already loaded, consider the version already
    // bumped so we don't increment it again on the next keystroke.
    _versionBumped = false;
    return ScenarioEditorState(draft: initialScenario);
  }

  ScenarioRepository get _repo => ref.read(scenarioRepositoryProvider);

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Increments the patch segment of a semver string `major.minor.patch`.
  /// Falls back gracefully for non-semver strings (appends `.1`).
  static String _bumpPatch(String version) {
    final parts = version.split('.');
    if (parts.length == 3) {
      final patch = int.tryParse(parts[2]) ?? 0;
      return '${parts[0]}.${parts[1]}.${patch + 1}';
    }
    if (parts.length == 2) return '${parts[0]}.${parts[1]}.1';
    return '$version.1';
  }

  /// Marks the draft dirty and schedules a debounced draft file write.
  /// On the very first edit of a previously-published scenario (startDirty
  /// was false when the editor opened), bumps the patch version once.
  void _markDirty(Scenario newDraft) {
    Scenario draft = newDraft;
    if (!_versionBumped && !state.isDirty) {
      _versionBumped = true;
      draft = draft.copyWith(version: _bumpPatch(draft.version));
    }
    state = state.copyWith(
      draft: draft,
      isDirty: true,
      clearValidationError: true,
    );
    _scheduleDraftSave();
  }

  /// Whether we have written the draft at least once this session.
  /// Used to invalidate the list provider the first time so new scenarios
  /// (which have no published file) appear immediately in the scenario list.
  bool _draftWrittenOnce = false;

  /// Debounces draft persistence: waits 800 ms after the last change.
  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _writeDraft);
  }

  Future<void> _writeDraft() async {
    state = state.copyWith(isDraftSaving: true);
    try {
      await _repo.saveDraft(state.draft);
      // On the first write, refresh the scenario list so that orphan drafts
      // (brand-new scenarios never yet published) appear immediately without
      // requiring an app restart.
      if (!_draftWrittenOnce) {
        _draftWrittenOnce = true;
        ref.invalidate(scenarioListWithStatusProvider);
      }
    } finally {
      state = state.copyWith(isDraftSaving: false);
    }
  }

  // ── Called by _EditorBody when a draft was loaded on open ─────────────────

  /// Marks the state dirty without touching the draft file — used when the
  /// editor was opened and a pre-existing draft was loaded as the initial state.
  void markDirtyFromDraft() {
    if (state.isDirty) return; // already dirty, nothing to do
    // Draft was created in a previous session — version already bumped then.
    _versionBumped = true;
    state = state.copyWith(isDirty: true);
  }

  // ── Public mutation API ────────────────────────────────────────────────────

  void updateMeta({
    String? name,
    String? description,
    String? author,
  }) {
    _markDirty(state.draft.copyWith(
      name: name,
      description: description,
      author: author,
      updatedAt: DateTime.now(),
    ));
  }

  /// Updates the version string explicitly (called when the user edits the
  /// Major or Minor fields). Marks [_versionBumped] so the automatic patch
  /// increment does not fire on top of the user's intentional change.
  void updateVersion(String version) {
    // Treat a manual version edit the same as "already bumped" so _markDirty
    // does not increment the patch a second time.
    _versionBumped = true;
    _markDirty(state.draft.copyWith(
      version: version,
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
      await _repo.save(state.draft);
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
