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

class _ScenarioGroup extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Use the first entry's name as the group title (all versions share a name).
    final groupName = versions.first.scenario.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ...versions.map((entry) => _ScenarioVersionTile(
                entry: entry,
                onDeletePublished: onDeletePublished,
                onDeleteDraft: onDeleteDraft,
              )),
        ],
      ),
    );
  }
}

// ── Single version row ───────────────────────────────────────────────────────

class _ScenarioVersionTile extends StatelessWidget {
  final ({Scenario scenario, bool hasDraft, bool publishedExists}) entry;
  final void Function(Scenario) onDeletePublished;
  final void Function(Scenario) onDeleteDraft;

  const _ScenarioVersionTile({
    required this.entry,
    required this.onDeletePublished,
    required this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final s = entry.scenario;
    final colorScheme = Theme.of(context).colorScheme;
    final isOrphanDraft = !entry.publishedExists;

    return ListTile(
      title: Row(
        children: [
          Text('v${s.version}'),
          const SizedBox(width: 8),
          // Draft badge
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
            onPressed: () => context.go(
                '/editor/${Uri.encodeComponent(s.id)}/${Uri.encodeComponent(s.version)}'),
            tooltip: isOrphanDraft ? 'Continue editing draft' : 'Edit',
          ),
          // Discard-draft button — only when a draft exists alongside a
          // published file (orphan drafts are deleted via the delete button).
          if (entry.hasDraft && entry.publishedExists)
            IconButton(
              icon: Icon(Icons.undo, size: 18, color: colorScheme.tertiary),
              tooltip: 'Discard draft (revert to published)',
              onPressed: () => onDeleteDraft(s),
            ),
          // Delete button — deletes the published file (and draft).
          // For orphan drafts this deletes the draft entirely.
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
      onTap: () => context.go(
          '/editor/${Uri.encodeComponent(s.id)}/${Uri.encodeComponent(s.version)}'),
    );
  }
}
