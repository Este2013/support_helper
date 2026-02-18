import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/scenario/answer.dart';
import '../../data/models/scenario/answer_destination.dart';
import '../../data/models/scenario/external_link.dart';
import '../../data/models/scenario/question.dart';
import '../../data/models/scenario/scenario.dart';
import '../../providers/editor_providers.dart';
import 'answer_editor_row.dart';
import 'markdown_editor_widget.dart';

// ---------------------------------------------------------------------------
// Compact tile — shown in the list. Tapping the edit icon opens the dialog.
// ---------------------------------------------------------------------------

class QuestionEditorTile extends StatelessWidget {
  final Question question;
  final Scenario initialScenario;
  final ScenarioEditor notifier;
  /// Index within its reorderable list section (used by ReorderableDragStartListener).
  final int reorderIndex;

  const QuestionEditorTile({
    super.key,
    required this.question,
    required this.initialScenario,
    required this.notifier,
    required this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotes = question.notes.trim().isNotEmpty;
    final hasScript = question.pythonScriptPath != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ReorderableDragStartListener(
          index: reorderIndex,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(
          question.title.isEmpty ? '(untitled)' : question.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(question.id,
                style: const TextStyle(fontSize: 11)),
            if (hasNotes) ...[
              const SizedBox(width: 6),
              const Icon(Icons.notes, size: 12),
            ],
            if (hasScript) ...[
              const SizedBox(width: 6),
              const Icon(Icons.terminal, size: 12),
            ],
            if (question.answers.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '${question.answers.length} ans',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error),
          tooltip: 'Delete question',
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => _openEditDialog(context),
      ),
    );
  }

  void _openEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionEditorDialog(
        initialScenario: initialScenario,
        questionId: question.id,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
            'Delete "${question.title.isEmpty ? question.id : question.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) notifier.deleteQuestion(question.id);
  }
}

// ---------------------------------------------------------------------------
// Full editor dialog — opened from the tile's edit button.
// ---------------------------------------------------------------------------

class QuestionEditorDialog extends ConsumerStatefulWidget {
  /// The scenario object this editor is bound to (for the Riverpod family key).
  final Scenario initialScenario;
  /// The ID of the question being edited.
  final String questionId;

  const QuestionEditorDialog({
    super.key,
    required this.initialScenario,
    required this.questionId,
  });

  @override
  ConsumerState<QuestionEditorDialog> createState() =>
      _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends ConsumerState<QuestionEditorDialog> {
  late TextEditingController _idCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _scriptCtrl;
  late TextEditingController _folderCtrl;
  /// Tracks the question ID being edited (can change when user edits the ID field).
  late String _currentQuestionId;

  ScenarioEditor get _notifier =>
      ref.read(scenarioEditorProvider(widget.initialScenario).notifier);

  @override
  void initState() {
    super.initState();
    _currentQuestionId = widget.questionId;
    // Read from the LIVE provider state, not from the widget.initialScenario
    // snapshot — the snapshot may predate the question being added (e.g. when
    // the dialog is opened immediately after addQuestion is called).
    final liveState =
        ref.read(scenarioEditorProvider(widget.initialScenario));
    final q = liveState.draft.questionById(widget.questionId) ??
        widget.initialScenario.questionById(widget.questionId)!;
    _idCtrl = TextEditingController(text: q.id);
    _titleCtrl = TextEditingController(text: q.title);
    _notesCtrl = TextEditingController(text: q.notes);
    _scriptCtrl = TextEditingController(text: q.pythonScriptPath ?? '');
    _folderCtrl = TextEditingController(text: q.folder);

    // MarkdownAutoPreview doesn't fire onChanged — listen directly.
    _notesCtrl.addListener(_save);
  }

  @override
  void dispose() {
    _notesCtrl.removeListener(_save);
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _scriptCtrl.dispose();
    _folderCtrl.dispose();
    super.dispose();
  }

  void _save() {
    // Look up the live question so we don't overwrite answers/links edited
    // concurrently (though the dialog is modal, it's safer to preserve them).
    final liveState =
        ref.read(scenarioEditorProvider(widget.initialScenario));
    final liveQ = liveState.draft.questionById(_currentQuestionId);
    if (liveQ == null) return; // question was deleted externally

    final updated = liveQ.copyWith(
      id: _idCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text,
      pythonScriptPath: _scriptCtrl.text.trim().isEmpty
          ? null
          : _scriptCtrl.text.trim(),
      clearPythonScript: _scriptCtrl.text.trim().isEmpty,
      folder: _folderCtrl.text.trim(),
    );
    // After saving, the question's ID in the draft may change — track it.
    _notifier.updateQuestion(_currentQuestionId, updated);
    _currentQuestionId = updated.id;
  }

  Future<void> _browseScript() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['py'],
      dialogTitle: 'Select Python Script',
    );
    final path = result?.files.single.path;
    if (path != null) {
      _scriptCtrl.text = path;
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch live editor state so answers/links updates show immediately.
    final editorState =
        ref.watch(scenarioEditorProvider(widget.initialScenario));
    final liveQ = editorState.draft.questionById(_currentQuestionId);
    if (liveQ == null) {
      // Question was deleted while dialog was open
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.of(context).pop());
      return const SizedBox.shrink();
    }

    final allQuestions = editorState.draft.questions;

    // Collect existing folder names for autocomplete
    final existingFolders = allQuestions
        .map((q) => q.folder)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Column(
          children: [
            // ── Title bar ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      liveQ.title.isEmpty ? 'Edit Question' : liveQ.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID + Title row
                    Row(
                      children: [
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _idCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Question ID',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _save(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Folder field (with autocomplete from existing folders)
                    _FolderField(
                      controller: _folderCtrl,
                      existingFolders: existingFolders,
                      onChanged: _save,
                    ),
                    const SizedBox(height: 16),

                    // Notes (markdown)
                    Text('Notes',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    MarkdownEditorWidget(controller: _notesCtrl),
                    const SizedBox(height: 16),

                    // Python script
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _scriptCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Python Script Path (optional)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _browseScript,
                          icon: const Icon(Icons.folder_open, size: 16),
                          label: const Text('Browse'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // External links
                    _SectionHeader(
                      label: 'External Links',
                      onAdd: () => _notifier.addExternalLink(
                        _currentQuestionId,
                        const ExternalLink(
                            label: 'New Link', url: 'https://'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ExternalLinksEditor(
                      question: liveQ,
                      notifier: _notifier,
                    ),
                    const SizedBox(height: 20),

                    // Answers
                    _SectionHeader(
                      label: 'Answers',
                      onAdd: () => _notifier.addAnswer(
                        _currentQuestionId,
                        const Answer(
                            label: 'New Answer',
                            destination: DestinationEnd()),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _AnswersEditor(
                      question: liveQ,
                      allQuestions: allQuestions,
                      notifier: _notifier,
                    ),
                  ],
                ),
              ),
            ),
            // ── Footer ────────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Folder autocomplete field
// ---------------------------------------------------------------------------

/// Stateful so the Autocomplete widget is created only once and survives
/// parent rebuilds — preventing the internal controller from resetting the
/// cursor/selection on every keystroke.
class _FolderField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> existingFolders;
  final VoidCallback onChanged;

  const _FolderField({
    required this.controller,
    required this.existingFolders,
    required this.onChanged,
  });

  @override
  State<_FolderField> createState() => _FolderFieldState();
}

class _FolderFieldState extends State<_FolderField> {
  // Autocomplete's internal TextEditingController — obtained in fieldViewBuilder
  // and held here so we can propagate external clears (e.g. the X button).
  TextEditingController? _autoCtrl;

  @override
  Widget build(BuildContext context) {
    // Rebuild hint only; the Autocomplete itself does NOT use initialValue
    // after first build, so no cursor reset occurs.
    return Autocomplete<String>(
      optionsBuilder: (value) {
        if (value.text.isEmpty) return widget.existingFolders;
        return widget.existingFolders.where((f) =>
            f.toLowerCase().contains(value.text.toLowerCase()));
      },
      onSelected: (value) {
        widget.controller.text = value;
        _autoCtrl?.text = value;
        widget.onChanged();
      },
      fieldViewBuilder: (ctx, autoCtrl, focusNode, onSubmit) {
        // Capture the internal controller on first build only.
        if (_autoCtrl == null) {
          _autoCtrl = autoCtrl;
          // Seed it with the current value from the outer controller.
          autoCtrl.text = widget.controller.text;
          // Forward changes from the autocomplete ctrl → outer controller.
          autoCtrl.addListener(() {
            if (autoCtrl.text != widget.controller.text) {
              widget.controller.text = autoCtrl.text;
              widget.onChanged();
            }
          });
        }

        return StatefulBuilder(
          builder: (_, setFieldState) {
            return TextField(
              controller: autoCtrl,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Folder (optional)',
                hintText: widget.existingFolders.isEmpty
                    ? 'e.g. "Diagnostics"'
                    : widget.existingFolders.join(', '),
                isDense: true,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.folder_outlined, size: 16),
                suffixIcon: autoCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          autoCtrl.clear();
                          widget.controller.clear();
                          widget.onChanged();
                          setFieldState(() {}); // hide the X immediately
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setFieldState(() {}), // toggle X button
              onSubmitted: (_) => onSubmit(),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section header with an add button
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;

  const _SectionHeader({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 14),
          label: Text('Add'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// External links sub-editor that watches live notifier state
// ---------------------------------------------------------------------------

class _ExternalLinksEditor extends StatelessWidget {
  final Question question;
  final ScenarioEditor notifier;

  const _ExternalLinksEditor(
      {required this.question, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (question.externalLinks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('No external links.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13)),
      );
    }
    return Column(
      children: question.externalLinks
          .asMap()
          .entries
          .map((e) => _ExternalLinkRow(
                link: e.value,
                onChanged: (updated) {
                  final links =
                      List<ExternalLink>.from(question.externalLinks);
                  links[e.key] = updated;
                  notifier.updateQuestion(
                    question.id,
                    question.copyWith(externalLinks: links),
                  );
                },
                onDelete: () =>
                    notifier.removeExternalLink(question.id, e.key),
              ))
          .toList(),
    );
  }
}

class _ExternalLinkRow extends StatefulWidget {
  final ExternalLink link;
  final ValueChanged<ExternalLink> onChanged;
  final VoidCallback onDelete;

  const _ExternalLinkRow({
    required this.link,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ExternalLinkRow> createState() => _ExternalLinkRowState();
}

class _ExternalLinkRowState extends State<_ExternalLinkRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.link.label);
    _urlCtrl = TextEditingController(text: widget.link.url);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => widget.onChanged(
                  ExternalLink(
                      label: _labelCtrl.text, url: _urlCtrl.text)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => widget.onChanged(
                  ExternalLink(
                      label: _labelCtrl.text, url: _urlCtrl.text)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: widget.onDelete,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Answers sub-editor
// ---------------------------------------------------------------------------

class _AnswersEditor extends StatelessWidget {
  final Question question;
  final List<Question> allQuestions;
  final ScenarioEditor notifier;

  const _AnswersEditor({
    required this.question,
    required this.allQuestions,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (question.answers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('No answers yet.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13)),
      );
    }
    return Column(
      children: question.answers
          .asMap()
          .entries
          .map((e) => AnswerEditorRow(
                key: ValueKey('${question.id}_ans_${e.key}'),
                answer: e.value,
                allQuestions: allQuestions,
                parentQuestionId: question.id,
                onChanged: (updated) =>
                    notifier.updateAnswer(question.id, e.key, updated),
                onDelete: () =>
                    notifier.deleteAnswer(question.id, e.key),
              ))
          .toList(),
    );
  }
}
