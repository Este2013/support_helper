import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasources/scenario_data_source.dart';
import '../data/models/scenario/scenario.dart';
import '../data/models/scenario/question.dart';
import '../data/models/scenario/answer.dart';
import '../data/models/scenario/external_link.dart';
import 'scenario_providers.dart';
import 'settings_provider.dart';

part 'editor_providers.g.dart';

class ScenarioEditorState {
  final Scenario draft;
  final bool isDirty;
  final String? validationError;

  /// True while the published file is being written (Save in progress).
  final bool isSaving;

  /// True while the background draft file is being written.
  final bool isDraftSaving;

  /// True while the server push is in progress (Publish in progress).
  /// Can be true independently of [isSaving] (publish starts after local save).
  final bool isPublishing;

  /// Non-null when the local save succeeded but the server push failed.
  /// Shown as a non-blocking warning snackbar in the editor UI.
  final String? syncWarning;

  const ScenarioEditorState({
    required this.draft,
    this.isDirty = false,
    this.validationError,
    this.isSaving = false,
    this.isDraftSaving = false,
    this.isPublishing = false,
    this.syncWarning,
  });

  /// True while any async operation (save or publish) is in progress.
  /// Used to disable action buttons to prevent double-submits.
  bool get isBusy => isSaving || isPublishing;

  ScenarioEditorState copyWith({
    Scenario? draft,
    bool? isDirty,
    String? validationError,
    bool clearValidationError = false,
    bool? isSaving,
    bool? isDraftSaving,
    bool? isPublishing,
    String? syncWarning,
    bool clearSyncWarning = false,
  }) =>
      ScenarioEditorState(
        draft: draft ?? this.draft,
        isDirty: isDirty ?? this.isDirty,
        validationError: clearValidationError
            ? null
            : (validationError ?? this.validationError),
        isSaving: isSaving ?? this.isSaving,
        isDraftSaving: isDraftSaving ?? this.isDraftSaving,
        isPublishing: isPublishing ?? this.isPublishing,
        syncWarning: clearSyncWarning
            ? null
            : (syncWarning ?? this.syncWarning),
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
    _versionBumped = false;
    return ScenarioEditorState(draft: initialScenario);
  }

  ScenarioDataSource get _repo => ref.read(scenarioRepositoryProvider);

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
  /// On the very first edit of a previously-published scenario, bumps the patch
  /// version once.
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

  bool _draftWrittenOnce = false;

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _writeDraft);
  }

  Future<void> _writeDraft() async {
    state = state.copyWith(isDraftSaving: true);
    try {
      await _repo.saveDraft(state.draft);
      if (!_draftWrittenOnce) {
        _draftWrittenOnce = true;
        ref.invalidate(scenarioListWithStatusProvider);
      }
    } finally {
      state = state.copyWith(isDraftSaving: false);
    }
  }

  // ── Called by _EditorBody when a draft was loaded on open ─────────────────

  void markDirtyFromDraft() {
    if (state.isDirty) return;
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

  void updateVersion(String version) {
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

  void moveQuestionToFolder(String questionId, String folder) {
    final q = state.draft.questionById(questionId);
    if (q == null) return;
    updateQuestion(questionId, q.copyWith(folder: folder));
  }

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

  // ── Save (local-only) ──────────────────────────────────────────────────────

  /// Saves the scenario to local disk only. The draft file is deleted.
  /// Does NOT push to the server — use [saveAndPublish] for that.
  ///
  /// Returns true on success, false if validation failed or the write errored.
  Future<bool> save() async {
    _draftTimer?.cancel();
    _draftTimer = null;

    final error = state.draft.validate();
    if (error != null) {
      state = state.copyWith(validationError: error);
      return false;
    }
    state = state.copyWith(isSaving: true, clearSyncWarning: true);
    try {
      await _repo.save(state.draft);
      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);
      state = state.copyWith(
        isDirty: false,
        isSaving: false,
        clearValidationError: true,
      );
    } catch (e) {
      state = state.copyWith(
          validationError: 'Save failed: $e', isSaving: false);
      return false;
    }

    return true;
  }

  // ── Save + Publish (local save then server push) ───────────────────────────

  /// Saves locally (same as [save]) then pushes to the server.
  ///
  /// On successful push: updates [draft.source] to [ScenarioSource.remote]
  /// and persists that change locally so the Server chip appears immediately.
  ///
  /// On push failure: returns true (local save succeeded) but sets
  /// [syncWarning] with an error message — non-blocking.
  ///
  /// Returns false only when the local save itself fails (validation or I/O).
  Future<bool> saveAndPublish() async {
    // Phase 1: local save (reuse existing logic).
    final localOk = await save();
    if (!localOk) return false;

    // Phase 2: server push.
    final syncService = ref.read(scenarioSyncServiceProvider);
    if (syncService == null) {
      // No server configured — treat as a plain local save.
      return true;
    }

    state = state.copyWith(isPublishing: true, clearSyncWarning: true);
    try {
      await syncService.push(state.draft);

      // Mark the scenario as remote-origin and re-save so the chip updates.
      final published = state.draft.copyWith(source: ScenarioSource.remote);
      await _repo.save(published);
      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);
      ref.invalidate(scenarioRemoteMetaProvider);
      state = state.copyWith(draft: published, isPublishing: false);
    } catch (e) {
      state = state.copyWith(
        isPublishing: false,
        syncWarning: 'Saved locally. Server push failed: $e',
      );
    }

    return true;
  }
}
