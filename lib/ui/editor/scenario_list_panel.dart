import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/scenario/scenario.dart';
import '../../data/services/file_import_export_service.dart';
import '../../providers/scenario_providers.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import '../shared/confirm_dialog.dart';

class ScenarioListPanel extends ConsumerWidget {
  const ScenarioListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(scenarioListWithStatusProvider);

    return listAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
          error: e,
          onRetry: () => ref.invalidate(scenarioListWithStatusProvider)),
      data: (entries) {
        // Group by scenario id; each group collects all (version, hasDraft,
        // publishedExists) tuples for that id.
        final grouped =
            <String, List<({Scenario scenario, bool hasDraft, bool publishedExists})>>{};
        for (final e in entries) {
          grouped.putIfAbsent(e.scenario.id, () => []).add(e);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Scenarios'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Import JSON',
                onPressed: () => _import(context, ref),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: grouped.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('No scenarios yet.'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => context.go('/editor/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Scenario'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: grouped.entries.map((entry) {
                    return _ScenarioGroup(
                      scenarioId: entry.key,
                      versions: entry.value,
                      onDeletePublished: (s) =>
                          _deletePublished(context, ref, s),
                      onDeleteDraft: (s) => _deleteDraft(context, ref, s),
                    );
                  }).toList(),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.go('/editor/new'),
            tooltip: 'New Scenario',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final service = FileImportExportService();
    final path = await service.pickJsonFileToImport();
    if (path == null) return;
    try {
      final repo = ref.read(scenarioRepositoryProvider);
      final s = await repo.importFromFile(path);
      ref.invalidate(scenarioListWithStatusProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${s.name}" v${s.version}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _deletePublished(
      BuildContext context, WidgetRef ref, Scenario s) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Scenario',
      message: 'Delete "${s.name}" v${s.version}? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    final repo = ref.read(scenarioRepositoryProvider);
    await repo.delete(s.id, s.version);
    ref.invalidate(scenarioListWithStatusProvider);
  }

  Future<void> _deleteDraft(
      BuildContext context, WidgetRef ref, Scenario s) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Discard Draft',
      message:
          'Discard the unsaved draft for "${s.name}" v${s.version}? The published version will be kept.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!confirmed) return;
    final repo = ref.read(scenarioRepositoryProvider);
    await repo.deleteDraft(s.id, s.version);
    ref.invalidate(scenarioListWithStatusProvider);
  }
}

// ── Scenario group card ──────────────────────────────────────────────────────

class _ScenarioGroup extends StatefulWidget {
  final String scenarioId;
  final List<({Scenario scenario, bool hasDraft, bool publishedExists})> versions;
  final void Function(Scenario) onDeletePublished;
  final void Function(Scenario) onDeleteDraft;

  const _ScenarioGroup({
    required this.scenarioId,
    required this.versions,
    required this.onDeletePublished,
    required this.onDeleteDraft,
  });

  @override
  State<_ScenarioGroup> createState() => _ScenarioGroupState();
}

class _ScenarioGroupState extends State<_ScenarioGroup> {
  bool _showAllVersions = false;

  /// Compares two version strings numerically segment-by-segment.
  /// Returns > 0 if [a] is newer, < 0 if [b] is newer, 0 if equal.
  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final groupName = widget.versions.first.scenario.name;

    // Sort descending — newest first.
    final sorted = [...widget.versions]..sort(
        (a, b) => _compareVersions(b.scenario.version, a.scenario.version));

    final latest = sorted.first;
    final older = sorted.skip(1).toList();
    final hasOlder = older.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              groupName,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // ── Latest version ────────────────────────────────────────────────
          _ScenarioVersionTile(
            entry: latest,
            onDeletePublished: widget.onDeletePublished,
            onDeleteDraft: widget.onDeleteDraft,
          ),
          // ── Older versions (collapsed by default) ─────────────────────────
          if (hasOlder) ...[
            InkWell(
              onTap: () => setState(() => _showAllVersions = !_showAllVersions),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAllVersions
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAllVersions
                          ? 'Hide older versions'
                          : '${older.length} older version${older.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showAllVersions)
              ...older.map((entry) => _ScenarioVersionTile(
                    entry: entry,
                    onDeletePublished: widget.onDeletePublished,
                    onDeleteDraft: widget.onDeleteDraft,
                  )),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Single version row ───────────────────────────────────────────────────────

class _ScenarioVersionTile extends ConsumerWidget {
  final ({Scenario scenario, bool hasDraft, bool publishedExists}) entry;
  final void Function(Scenario) onDeletePublished;
  final void Function(Scenario) onDeleteDraft;

  const _ScenarioVersionTile({
    required this.entry,
    required this.onDeletePublished,
    required this.onDeleteDraft,
  });

  String _editorPath(Scenario s) =>
      '/editor/${Uri.encodeComponent(s.id)}/${Uri.encodeComponent(s.version)}';

  /// Tapping when both a published file AND a draft exist: ask the user
  /// whether to resume the draft or start fresh from the published version.
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final s = entry.scenario;
    // Orphan draft or no draft — go straight in.
    if (!entry.hasDraft || !entry.publishedExists) {
      context.go(_editorPath(s));
      return;
    }

    // Both exist — show the choice dialog.
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Draft Found'),
        content: Text(
          '"${s.name}" v${s.version} has an unsaved draft.\n\n'
          'Would you like to resume where you left off, or start fresh from the last published version?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null), // cancel
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('Start Fresh'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.edit_note, size: 16),
            label: const Text('Resume Draft'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (resume == null || !context.mounted) return;

    if (!resume) {
      // Discard the draft, then open the published version.
      final repo = ref.read(scenarioRepositoryProvider);
      await repo.deleteDraft(s.id, s.version);
      ref.invalidate(scenarioListWithStatusProvider);
    }
    if (context.mounted) context.go(_editorPath(s));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = entry.scenario;
    final colorScheme = Theme.of(context).colorScheme;
    final isOrphanDraft = !entry.publishedExists;

    return ListTile(
      title: Row(
        children: [
          Text('v${s.version}'),
          const SizedBox(width: 8),
          if (entry.hasDraft)
            Chip(
              label: Text(isOrphanDraft ? 'Unpublished Draft' : 'Draft'),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide.none,
              avatar: Icon(
                Icons.edit_note,
                size: 13,
                color: colorScheme.onTertiaryContainer,
              ),
              backgroundColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontSize: 11,
              ),
            ),
        ],
      ),
      subtitle: Text('${s.questions.length} questions • ${s.author}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _handleTap(context, ref),
            tooltip: isOrphanDraft ? 'Continue editing draft' : 'Edit',
          ),
          // Discard-draft button — only when a draft exists alongside a
          // published file (orphan drafts use the delete button instead).
          if (entry.hasDraft && entry.publishedExists)
            IconButton(
              icon: Icon(Icons.undo, size: 18, color: colorScheme.tertiary),
              tooltip: 'Discard draft (revert to published)',
              onPressed: () => onDeleteDraft(s),
            ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 18, color: colorScheme.error),
            onPressed: () => isOrphanDraft
                ? onDeleteDraft(s)
                : onDeletePublished(s),
            tooltip: isOrphanDraft ? 'Discard draft' : 'Delete',
          ),
        ],
      ),
      onTap: () => _handleTap(context, ref),
    );
  }
}
