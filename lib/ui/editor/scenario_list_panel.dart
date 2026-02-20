import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/scenario/scenario.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../data/services/file_import_export_service.dart';
import '../../providers/scenario_providers.dart';
import '../../providers/settings_provider.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import '../shared/confirm_dialog.dart';

// Convenience typedef for the extended list-entry record.
typedef _Entry = ({
  Scenario scenario,
  bool hasDraft,
  bool publishedExists,
  bool remoteExists,
  bool remoteIsNewer,
});

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
        // Group by scenario id.
        final grouped = <String, List<_Entry>>{};
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
      // Cast is safe: on desktop the provider always returns ScenarioRepository.
      final repo = ref.read(scenarioRepositoryProvider) as ScenarioRepository;
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
  final List<_Entry> versions;
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
          _ScenarioVersionTile(
            entry: latest,
            onDeletePublished: widget.onDeletePublished,
            onDeleteDraft: widget.onDeleteDraft,
          ),
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

class _ScenarioVersionTile extends ConsumerStatefulWidget {
  final _Entry entry;
  final void Function(Scenario) onDeletePublished;
  final void Function(Scenario) onDeleteDraft;

  const _ScenarioVersionTile({
    required this.entry,
    required this.onDeletePublished,
    required this.onDeleteDraft,
  });

  @override
  ConsumerState<_ScenarioVersionTile> createState() =>
      _ScenarioVersionTileState();
}

class _ScenarioVersionTileState extends ConsumerState<_ScenarioVersionTile> {
  bool _isLoading = false;

  _Entry get entry => widget.entry;

  String _editorPath(Scenario s) =>
      '/editor/${Uri.encodeComponent(s.id)}/${Uri.encodeComponent(s.version)}';

  // ── Tap handlers ────────────────────────────────────────────────────────────

  /// Primary tap: online-first if remote exists, draft-resume if draft exists.
  Future<void> _handleTap() async {
    final s = entry.scenario;

    // Remote-only stub (no local copy, no draft) — download first.
    if (!entry.publishedExists && !entry.hasDraft && entry.remoteExists) {
      await _downloadAndEdit(s);
      return;
    }

    // Orphan draft or no draft, no remote overlap → go straight in.
    if (!entry.hasDraft || !entry.publishedExists) {
      if (mounted) context.go(_editorPath(s));
      return;
    }

    // Both draft and published exist — ask.
    if (!mounted) return;
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
            onPressed: () => Navigator.of(ctx).pop(null),
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

    if (resume == null || !mounted) return;

    if (!resume) {
      final repo = ref.read(scenarioRepositoryProvider);
      await repo.deleteDraft(s.id, s.version);
      ref.invalidate(scenarioListWithStatusProvider);
    }
    if (mounted) context.go(_editorPath(s));
  }

  /// "Open from server" — pulls the remote version, overwrites local, opens editor.
  /// Falls back to the local copy if the network request fails.
  Future<void> _openFromServer() async {
    final s = entry.scenario;
    final syncService = ref.read(scenarioSyncServiceProvider);
    if (syncService == null) {
      if (mounted) context.go(_editorPath(s));
      return;
    }

    // If already in sync (same updatedAt), skip the network round-trip.
    if (entry.publishedExists && !entry.remoteIsNewer) {
      if (mounted) context.go(_editorPath(s));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final remote = await syncService.fetchOne(s.id, s.version);
      await ref.read(scenarioRepositoryProvider).save(remote);
      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);
      if (mounted) context.go(_editorPath(remote));
    } catch (_) {
      // Network failed — fall back to local copy.
      if (mounted) context.go(_editorPath(s));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// "Download to edit" — used for remote-only stubs (no local file at all).
  Future<void> _downloadAndEdit(Scenario stub) async {
    final syncService = ref.read(scenarioSyncServiceProvider);
    if (syncService == null) return;

    setState(() => _isLoading = true);
    try {
      final remote = await syncService.fetchOne(stub.id, stub.version);
      await ref.read(scenarioRepositoryProvider).save(remote);
      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);
      if (mounted) context.go(_editorPath(remote));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Publish an orphan draft to the server.
  Future<void> _publishDraft() async {
    final s = entry.scenario;
    final repo = ref.read(scenarioRepositoryProvider);
    final syncService = ref.read(scenarioSyncServiceProvider);
    if (syncService == null) return;

    setState(() => _isLoading = true);
    try {
      // The draft IS the only copy; load it explicitly.
      final draft = await repo.loadDraft(s.id, s.version) ?? s;

      // Publish locally first (writes published file, deletes draft).
      final published = draft.copyWith(source: ScenarioSource.remote);
      await repo.save(published);

      // Push to server.
      await syncService.push(published);

      ref.invalidate(scenarioListProvider);
      ref.invalidate(scenarioListWithStatusProvider);
      ref.invalidate(scenarioRemoteMetaProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Published to server.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publish failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = entry.scenario;
    final colorScheme = Theme.of(context).colorScheme;
    final isOrphanDraft = !entry.publishedExists && entry.hasDraft;
    final isRemoteOnly = !entry.publishedExists && !entry.hasDraft && entry.remoteExists;
    final settings = ref.watch(appSettingsNotifierProvider).valueOrNull;
    final canPush = settings?.canPush == true && settings?.hasServer == true;

    Widget titleRow = Row(
      children: [
        Text('v${s.version}'),
        const SizedBox(width: 8),
        // Draft chip
        if (entry.hasDraft)
          _chip(
            icon: Icons.edit_note,
            label: isOrphanDraft ? 'Unpublished Draft' : 'Draft',
            background: colorScheme.tertiaryContainer,
            foreground: colorScheme.onTertiaryContainer,
          ),
        // Server chip
        if (s.source == ScenarioSource.remote || entry.remoteExists) ...[
          if (entry.hasDraft) const SizedBox(width: 4),
          _chip(
            icon: Icons.cloud_outlined,
            label: 'Server',
            background: colorScheme.secondaryContainer,
            foreground: colorScheme.onSecondaryContainer,
          ),
        ],
      ],
    );

    // Subtitle line — varies by scenario state.
    final String subtitleText;
    if (isRemoteOnly) {
      subtitleText = 'On server — not downloaded yet';
    } else if (entry.remoteIsNewer && entry.publishedExists) {
      subtitleText = '↑ Newer version on server';
    } else {
      subtitleText = '${s.questions.length} questions'
          '${s.author.isNotEmpty ? ' • ${s.author}' : ''}';
    }

    Widget subtitle = Text(
      subtitleText,
      style: (entry.remoteIsNewer && entry.publishedExists)
          ? TextStyle(color: colorScheme.primary, fontSize: 12)
          : null,
    );

    // Trailing buttons — vary based on state.
    final trailing = _isLoading
        ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remote-only: "Download to edit" is the primary action.
              if (isRemoteOnly)
                IconButton(
                  icon: Icon(Icons.cloud_download_outlined,
                      size: 18, color: colorScheme.primary),
                  tooltip: 'Download and edit',
                  onPressed: () => _downloadAndEdit(s),
                )

              // Both local + remote: primary = open from server; secondary = edit local.
              else if (entry.remoteExists && entry.publishedExists) ...[
                IconButton(
                  icon: Icon(Icons.cloud_sync_outlined,
                      size: 18, color: colorScheme.primary),
                  tooltip: 'Open from server'
                      '${entry.remoteIsNewer ? ' (newer)' : ''}',
                  onPressed: () => _openFromServer(),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit local copy',
                  onPressed: () => _openLocalOnly(),
                ),
              ]

              // Local-only (no remote) — standard edit button.
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: _handleTap,
                  tooltip: isOrphanDraft ? 'Continue editing draft' : 'Edit',
                ),

              // Publish button for orphan drafts (editor role only).
              if (isOrphanDraft && canPush)
                IconButton(
                  icon: Icon(Icons.cloud_upload_outlined,
                      size: 18, color: colorScheme.primary),
                  tooltip: 'Publish to server',
                  onPressed: _publishDraft,
                ),

              // Discard-draft button (draft + published exist).
              if (entry.hasDraft && entry.publishedExists)
                IconButton(
                  icon: Icon(Icons.undo, size: 18, color: colorScheme.tertiary),
                  tooltip: 'Discard draft (revert to published)',
                  onPressed: () => widget.onDeleteDraft(s),
                ),

              // Delete button — hidden for remote-only stubs (nothing to delete locally).
              if (!isRemoteOnly)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: colorScheme.error),
                  onPressed: () => isOrphanDraft
                      ? widget.onDeleteDraft(s)
                      : widget.onDeletePublished(s),
                  tooltip: isOrphanDraft ? 'Discard draft' : 'Delete',
                ),
            ],
          );

    return ListTile(
      title: titleRow,
      subtitle: subtitle,
      trailing: trailing,
      onTap: _isLoading ? null : _handleTap,
    );
  }

  // ── Opens the local copy without touching the remote version. ───────────────
  Future<void> _openLocalOnly() async {
    final s = entry.scenario;
    if (!entry.hasDraft || !entry.publishedExists) {
      if (mounted) context.go(_editorPath(s));
      return;
    }
    // Same draft-resume dialog as the normal tap flow.
    await _handleTap();
  }

  // ── Chip helper ─────────────────────────────────────────────────────────────
  Widget _chip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Chip(
      label: Text(label),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
      avatar: Icon(icon, size: 13, color: foreground),
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground, fontSize: 11),
    );
  }
}
