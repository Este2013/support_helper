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
    final scenariosAsync = ref.watch(scenarioListProvider);

    return scenariosAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
          error: e,
          onRetry: () => ref.invalidate(scenarioListProvider)),
      data: (scenarios) {
        // Group by id, show multiple versions
        final grouped = <String, List<Scenario>>{};
        for (final s in scenarios) {
          grouped.putIfAbsent(s.id, () => []).add(s);
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
                        onPressed: () =>
                            context.go('/editor/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Scenario'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: grouped.entries.map((entry) {
                    final versions = entry.value;
                    return _ScenarioGroup(
                      scenarioId: entry.key,
                      versions: versions,
                      onDelete: (s) => _delete(context, ref, s),
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
      ref.invalidate(scenarioListProvider);
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

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Scenario s) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Scenario',
      message:
          'Delete "${s.name}" v${s.version}? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    final repo = ref.read(scenarioRepositoryProvider);
    await repo.delete(s.id, s.version);
    ref.invalidate(scenarioListProvider);
  }
}

class _ScenarioGroup extends StatelessWidget {
  final String scenarioId;
  final List<Scenario> versions;
  final void Function(Scenario) onDelete;

  const _ScenarioGroup({
    required this.scenarioId,
    required this.versions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              versions.first.name,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...versions.map((s) => ListTile(
                title: Text('v${s.version}'),
                subtitle: Text(
                    '${s.questions.length} questions • ${s.author}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => context.go(
                          '/editor/${Uri.encodeComponent(s.id)}/${Uri.encodeComponent(s.version)}'),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => onDelete(s),
                      tooltip: 'Delete',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
