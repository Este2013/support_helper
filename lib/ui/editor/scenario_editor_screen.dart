import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/scenario/answer.dart';
import '../../data/models/scenario/answer_destination.dart';
import '../../data/models/scenario/question.dart';
import '../../data/models/scenario/scenario.dart';
import '../../data/services/file_import_export_service.dart';
import '../../providers/editor_providers.dart';
import '../../providers/scenario_providers.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'question_editor_tile.dart';

class ScenarioEditorScreen extends ConsumerWidget {
  final String? scenarioId;
  final String? scenarioVersion;

  const ScenarioEditorScreen({super.key, required this.scenarioId, required this.scenarioVersion});

  /// Generates a scenario ID from the machine hostname + creation date +
  /// a short random suffix. Format: `{host8}_{yyyyMMdd}_{rand6}`.
  /// Keeps only alphanumeric + hyphens to stay filename-safe.
  static String _generateScenarioId(DateTime now) {
    final raw = Platform.localHostname;
    final host = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    final hostPart = host.length > 8 ? host.substring(0, 8) : host;
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = const Uuid().v4().replaceAll('-', '').substring(0, 6);
    return '$hostPart-$datePart-$rand';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scenarioId == null) {
      // New scenario — generate a stable ID from machine name + creation date.
      final now = DateTime.now();
      final blank = Scenario(id: _generateScenarioId(now), name: 'New Scenario', version: '1.0.0', createdAt: now, updatedAt: now);
      return _EditorBody(initialScenario: blank, startDirty: false);
    }

    final editAsync = ref.watch(scenarioForEditingProvider(scenarioId!, scenarioVersion!));
    return editAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(error: e),
      data: (result) => _EditorBody(
        initialScenario: result.scenario,
        // If we loaded a draft, the editor starts dirty so the chip shows
        // immediately and the Save button is enabled.
        startDirty: result.hasDraft,
      ),
    );
  }
}

class _EditorBody extends ConsumerWidget {
  final Scenario initialScenario;

  /// Whether the editor should start in a dirty (draft) state.
  final bool startDirty;

  const _EditorBody({required this.initialScenario, required this.startDirty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(scenarioEditorProvider(initialScenario));
    final notifier = ref.read(scenarioEditorProvider(initialScenario).notifier);

    // On first build, if we loaded a draft, mark the state dirty so the chip
    // and Save button activate without requiring a user edit first.
    if (startDirty && !editorState.isDirty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.markDirtyFromDraft();
      });
    }

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => notifier.save()},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(child: Text(editorState.draft.name, overflow: TextOverflow.ellipsis)),
                if (editorState.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      avatar: editorState.isDraftSaving
                          ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Theme.of(context).colorScheme.onTertiaryContainer))
                          : Icon(Icons.edit_note, size: 14, color: Theme.of(context).colorScheme.onTertiaryContainer),
                      label: Text(editorState.isDraftSaving ? 'Saving…' : 'Draft'),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      side: BorderSide.none,
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 11),
                    ),
                  ),
              ],
            ),
            actions: [
              if (editorState.validationError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(editorState.validationError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              TextButton.icon(onPressed: editorState.isSaving ? null : () => _export(context, ref, editorState.draft), icon: const Icon(Icons.upload_file, size: 16), label: const Text('Export')),
              FilledButton.icon(
                onPressed: editorState.isSaving
                    ? null
                    : () async {
                        final ok = await notifier.save();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scenario saved.')));
                        }
                      },
                icon: editorState.isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 16),
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta panel
              SizedBox(
                width: 260,
                child: _MetaPanel(draft: editorState.draft, notifier: notifier),
              ),
              const VerticalDivider(width: 1),
              // Questions list
              Expanded(
                child: _QuestionList(draft: editorState.draft, notifier: notifier, initialScenario: initialScenario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, Scenario scenario) async {
    final service = FileImportExportService();
    final path = await service.pickJsonFileToExport('${scenario.id}_v${scenario.version}.json');
    if (path == null) return;
    final repo = ref.read(scenarioRepositoryProvider);
    await repo.exportToFile(scenario, path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    }
  }
}

class _MetaPanel extends StatefulWidget {
  final Scenario draft;
  final ScenarioEditor notifier;

  const _MetaPanel({required this.draft, required this.notifier});

  @override
  State<_MetaPanel> createState() => _MetaPanelState();
}

class _MetaPanelState extends State<_MetaPanel> {
  late TextEditingController _nameCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _majorCtrl;
  late TextEditingController _minorCtrl;

  /// The last version string we synced the major/minor controllers from.
  /// Used in didUpdateWidget to detect external patch bumps.
  String _lastSyncedVersion = '';

  /// Splits a version string into [major, minor, patch] integers.
  static (int, int, int) _parseVersion(String v) {
    final parts = v.split('.');
    final major = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 1) : 1;
    final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return (major, minor, patch);
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.name);
    _authorCtrl = TextEditingController(text: widget.draft.author);
    _descCtrl = TextEditingController(text: widget.draft.description);
    final (major, minor, _) = _parseVersion(widget.draft.version);
    _majorCtrl = TextEditingController(text: '$major');
    _minorCtrl = TextEditingController(text: '$minor');
    _lastSyncedVersion = widget.draft.version;
  }

  @override
  void didUpdateWidget(_MetaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVersion = widget.draft.version;
    // Sync major/minor only when the version has changed externally
    // (e.g. patch was bumped by the notifier on first edit of a published
    // scenario). We don't want to overwrite the user's in-progress edits.
    if (newVersion != _lastSyncedVersion) {
      _lastSyncedVersion = newVersion;
      final (major, minor, _) = _parseVersion(newVersion);
      // Only overwrite if the value actually changed, to avoid resetting cursor.
      if (_majorCtrl.text != '$major') _majorCtrl.text = '$major';
      if (_minorCtrl.text != '$minor') _minorCtrl.text = '$minor';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _majorCtrl.dispose();
    _minorCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.notifier.updateMeta(name: _nameCtrl.text.trim(), description: _descCtrl.text.trim(), author: _authorCtrl.text.trim());
  }

  /// Called when Major or Minor fields change.
  /// Reconstructs the full version string, preserving the current patch.
  void _emitVersion() {
    final (_, _, currentPatch) = _parseVersion(widget.draft.version);
    final major = int.tryParse(_majorCtrl.text.trim()) ?? 1;
    final minor = int.tryParse(_minorCtrl.text.trim()) ?? 0;
    final newVersion = '$major.$minor.$currentPatch';
    // Avoid a no-op update (which would still trigger _markDirty).
    if (newVersion == widget.draft.version) return;
    widget.notifier.updateVersion(newVersion);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (_, _, patch) = _parseVersion(widget.draft.version);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scenario Info', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          // ID: read-only, auto-generated
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'ID (auto-generated)',
              isDense: true,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              suffixIcon: Tooltip(
                message: 'Generated from machine name and creation date.\nCannot be changed.',
                child: Icon(Icons.lock_outline, size: 16, color: colorScheme.outline),
              ),
            ),
            child: Text(
              widget.draft.id,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          // Version: Major + Minor editable, Patch read-only (auto-managed)
          _VersionRow(majorCtrl: _majorCtrl, minorCtrl: _minorCtrl, patch: patch, onChanged: _emitVersion),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name', isDense: true, border: OutlineInputBorder()),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorCtrl,
            decoration: const InputDecoration(labelText: 'Author', isDense: true, border: OutlineInputBorder()),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder()),
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

/// Three-column version row: [Major] . [Minor] . [Patch (locked)]
class _VersionRow extends StatelessWidget {
  final TextEditingController majorCtrl;
  final TextEditingController minorCtrl;
  final int patch;
  final VoidCallback onChanged;

  const _VersionRow({required this.majorCtrl, required this.minorCtrl, required this.patch, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Shared input decoration for the editable number fields.
    InputDecoration editableDecoration(String label) => InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(), counterText: '');

    // Shared decoration for the read-only patch field.
    final lockedDecoration = InputDecoration(
      labelText: 'Patch',
      isDense: true,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      suffixIcon: Tooltip(
        message: 'Increments automatically on\nfirst edit of a published scenario.',
        child: Icon(Icons.lock_outline, size: 14, color: colorScheme.outline),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Version', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Row(
          children: [
            // Major
            Expanded(
              child: TextField(
                controller: majorCtrl,
                decoration: editableDecoration('Major'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                onChanged: (_) => onChanged(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
            ),
            // Minor
            Expanded(
              child: TextField(
                controller: minorCtrl,
                decoration: editableDecoration('Minor'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                onChanged: (_) => onChanged(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
            ),
            // Patch (read-only)
            Expanded(
              child: InputDecorator(
                decoration: lockedDecoration,
                child: Text('$patch', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Groups questions by folder and renders them in collapsible sections.
/// The global order of questions in `draft.questions` is preserved across all
/// folders; reordering within a folder moves items within their contiguous
/// block in the global list.
class _QuestionList extends StatefulWidget {
  final Scenario draft;
  final ScenarioEditor notifier;

  /// The initial scenario object used as the Riverpod family key for the editor.
  final Scenario initialScenario;

  const _QuestionList({required this.draft, required this.notifier, required this.initialScenario});

  @override
  State<_QuestionList> createState() => _QuestionListState();
}

class _QuestionListState extends State<_QuestionList> {
  /// Folders that are currently collapsed; root ('') is always expanded.
  final Set<String> _collapsed = {};

  /// Folders created via the "New Folder" dialog that are not yet populated
  /// with any questions. Kept alive so the empty folder header remains visible
  /// for the user to drag questions into.
  final Set<String> _pendingFolders = {};

  // ── Create folder ──────────────────────────────────────────────────────────
  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder name', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    // A folder only materialises when it has at least one question, so we
    // just ensure the name is tracked locally — the user can then drag a
    // question into it, or type it in the question dialog.
    if (name != null && name.isNotEmpty && context.mounted) {
      setState(() {
        // Keep the folder alive in the UI even before any question is dropped
        // into it. It will be removed from _pendingFolders automatically once
        // a question with that folder name exists in the draft.
        _pendingFolders.add(name);
        _collapsed.remove(name); // start expanded so the user can drop into it
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.draft.questions;

    // Build an ordered list of folder names, preserving first-occurrence order.
    final orderedFolders = <String>[];
    for (final q in questions) {
      if (!orderedFolders.contains(q.folder)) {
        orderedFolders.add(q.folder);
      }
    }

    // Merge pending (empty) folders in — they appear at the end until a
    // question is dropped into them. Also prune any that are now populated.
    final populatedFolders = questions.map((q) => q.folder).toSet();
    _pendingFolders.removeWhere(populatedFolders.contains);
    for (final pf in _pendingFolders) {
      if (!orderedFolders.contains(pf)) orderedFolders.add(pf);
    }

    // Toolbar row: section label + "New Folder" button.
    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text('Questions  (${questions.length})', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const Spacer(),
          TextButton.icon(onPressed: () => _showCreateFolderDialog(context), icon: const Icon(Icons.create_new_folder_outlined, size: 16), label: const Text('New Folder')),
        ],
      ),
    );

    if (questions.isEmpty && _pendingFolders.isEmpty) {
      return Scaffold(
        body: Column(
          children: [
            toolbar,
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    const Text('No questions yet. Add one below.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
        // +1 for the toolbar row at index 0
        itemCount: orderedFolders.length + 1,
        itemBuilder: (_, fi) {
          if (fi == 0) return toolbar;
          final folder = orderedFolders[fi - 1];
          final folderQuestions = questions.where((q) => q.folder == folder).toList();
          final isCollapsed = _collapsed.contains(folder);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FolderSection(
              key: ValueKey('folder_$folder'),
              folderName: folder,
              questions: folderQuestions,
              isCollapsed: isCollapsed,
              onToggleCollapse: () => setState(() {
                if (isCollapsed) {
                  _collapsed.remove(folder);
                } else {
                  _collapsed.add(folder);
                }
              }),
              onRenameFolder: folder.isEmpty ? null : (newName) => widget.notifier.renameFolder(folder, newName),
              onDeleteFolder: folder.isEmpty ? null : () => widget.notifier.deleteFolder(folder),
              // Reorder within this folder: map local → global indices
              onReorder: (oldLocal, newLocal) {
                final globalOld = questions.indexOf(folderQuestions[oldLocal]);
                final globalNew = questions.indexOf(folderQuestions[newLocal]);
                widget.notifier.reorderQuestions(globalOld, globalNew);
              },
              // Drag-from-another-folder: move question into this folder
              onDropQuestion: (questionId) => widget.notifier.moveQuestionToFolder(questionId, folder),
              initialScenario: widget.initialScenario,
              notifier: widget.notifier,
            ),
          );
        },
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final preset = await showDialog<Question>(context: context, builder: (_) => const _QuestionPresetDialog());
        if (preset == null || !context.mounted) return;
        // Add the question to the draft first so the editor dialog can find it.
        widget.notifier.addQuestion(preset);
        // Immediately open the editor dialog for the newly-added question.
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => QuestionEditorDialog(initialScenario: widget.initialScenario, questionId: preset.id),
          );
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Question'),
    );
  }
}

/// A collapsible section for one folder ('' = root / no folder).
/// The header is a [DragTarget] so questions can be dragged from other folders.
class _FolderSection extends StatefulWidget {
  final String folderName;
  final List<Question> questions;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final void Function(String newName)? onRenameFolder;
  final VoidCallback? onDeleteFolder;
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Called when a question is dragged onto this folder's header.
  final void Function(String questionId) onDropQuestion;
  final Scenario initialScenario;
  final ScenarioEditor notifier;

  const _FolderSection({
    super.key,
    required this.folderName,
    required this.questions,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onReorder,
    required this.onDropQuestion,
    required this.initialScenario,
    required this.notifier,
  });

  @override
  State<_FolderSection> createState() => _FolderSectionState();
}

class _FolderSectionState extends State<_FolderSection> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.folderName.isEmpty;
    final label = isRoot ? 'Ungrouped' : widget.folderName;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Folder header (also a DragTarget) ─────────────────────────────
        DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            // Only accept if the question isn't already in this folder.
            final q = widget.notifier.state.draft.questionById(details.data);
            return q != null && q.folder != widget.folderName;
          },
          onAcceptWithDetails: (details) {
            widget.onDropQuestion(details.data);
            setState(() => _isDragOver = false);
          },
          onMove: (_) => setState(() => _isDragOver = true),
          onLeave: (_) => setState(() => _isDragOver = false),
          builder: (ctx, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty || _isDragOver;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: isHovered ? colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isHovered ? Border.all(color: colorScheme.primary.withValues(alpha: 0.6), width: 1.5) : null,
              ),
              child: InkWell(
                onTap: widget.onToggleCollapse,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(isRoot ? Icons.inbox_outlined : (widget.isCollapsed ? Icons.folder : Icons.folder_open), size: 18, color: isRoot ? colorScheme.outline : colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('$label  (${widget.questions.length})', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isRoot ? colorScheme.outline : colorScheme.primary)),
                      const Spacer(),
                      if (!isRoot) ...[
                        IconButton(icon: const Icon(Icons.drive_file_rename_outline, size: 16), tooltip: 'Rename folder', onPressed: () => _showRenameDialog(context, widget.folderName)),
                        IconButton(
                          icon: Icon(Icons.folder_delete_outlined, size: 16, color: colorScheme.error),
                          tooltip: 'Remove folder (questions move to Ungrouped)',
                          onPressed: widget.onDeleteFolder,
                        ),
                      ],
                      Icon(widget.isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down, size: 18, color: colorScheme.outline),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // ── Question tiles ─────────────────────────────────────────────────
        if (!widget.isCollapsed)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.questions.length,
            onReorderItem: widget.onReorder,
            itemBuilder: (_, i) {
              final q = widget.questions[i];
              return _DraggableQuestionTile(key: ValueKey(q.id), question: q, initialScenario: widget.initialScenario, notifier: widget.notifier, reorderIndex: i);
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder name', border: OutlineInputBorder()),
          onSubmitted: (_) {
            widget.onRenameFolder?.call(ctrl.text.trim());
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              widget.onRenameFolder?.call(ctrl.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

/// Wraps [QuestionEditorTile] in a [LongPressDraggable] that carries the
/// question's ID as the drag data. Dropping onto a [_FolderSection] header
/// moves the question into that folder.
class _DraggableQuestionTile extends StatelessWidget {
  final Question question;
  final Scenario initialScenario;
  final ScenarioEditor notifier;
  final int reorderIndex;

  const _DraggableQuestionTile({super.key, required this.question, required this.initialScenario, required this.notifier, required this.reorderIndex});

  @override
  Widget build(BuildContext context) => LongPressDraggable<String>(
    data: question.id,
    // Compact ghost shown under the finger while dragging.
    feedback: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.drag_indicator, size: 18),
          title: Text(question.title.isEmpty ? question.id : question.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(question.id, style: const TextStyle(fontSize: 11)),
        ),
      ),
    ),
    // Dim the original tile while it is being dragged.
    childWhenDragging: Opacity(
      opacity: 0.35,
      child: QuestionEditorTile(question: question, initialScenario: initialScenario, notifier: notifier, reorderIndex: reorderIndex),
    ),
    child: QuestionEditorTile(question: question, initialScenario: initialScenario, notifier: notifier, reorderIndex: reorderIndex),
  );
}

/// Dialog for picking a question preset when adding a new question.
class _QuestionPresetDialog extends StatelessWidget {
  const _QuestionPresetDialog();

  String _newId() => 'q_${const Uuid().v4().substring(0, 8)}';

  Question _blank() => Question(id: _newId(), title: 'New Question');

  Question _yesNo() => Question(
    id: _newId(),
    title: 'New Yes/No Question',
    answers: const [
      Answer(label: 'Yes', destination: DestinationEnd()),
      Answer(label: 'No', destination: DestinationEnd()),
    ],
  );

  Question _windowsMac() => Question(
    id: _newId(),
    title: 'What OS is the customer using?',
    answers: const [
      Answer(label: 'Windows', destination: DestinationEnd()),
      Answer(label: 'macOS', destination: DestinationEnd()),
      Answer(label: 'Linux', destination: DestinationEnd()),
    ],
  );

  Question _workedOrNot() => Question(
    id: _newId(),
    title: 'Did that fix the issue?',
    answers: const [
      Answer(label: 'It worked!', destination: DestinationEnd()),
      Answer(label: "It didn't work", destination: DestinationEnd()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final presets = [
      (icon: Icons.article_outlined, label: 'Blank Question', description: 'Start from scratch', build: _blank),
      (icon: Icons.thumbs_up_down_outlined, label: 'Yes / No', description: 'Two answer buttons: Yes and No', build: _yesNo),
      (icon: Icons.computer, label: 'Windows / macOS / Linux', description: 'OS selection question', build: _windowsMac),
      (icon: Icons.check_circle_outline, label: 'It worked / It didn\'t', description: 'Follow-up resolution check', build: _workedOrNot),
    ];

    return AlertDialog(
      title: const Text('Add Question'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a preset to pre-fill the question:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 12),
            ...presets.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(p.icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p.description, style: Theme.of(context).textTheme.bodySmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  onTap: () => Navigator.of(context).pop(p.build()),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
    );
  }
}
