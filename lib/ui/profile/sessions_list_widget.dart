import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/profile/customer_profile.dart';
import '../../data/models/profile/scenario_session.dart';
import '../../data/models/scenario/scenario.dart';
import '../../providers/profile_providers.dart';
import '../../providers/scenario_providers.dart';
import 'session_card_widget.dart';

class SessionsListWidget extends ConsumerWidget {
  final CustomerProfile profile;

  const SessionsListWidget({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = profile.sessions
        .where((s) => s.status == SessionStatus.inProgress)
        .toList();
    final completed = profile.sessions
        .where((s) => s.status == SessionStatus.completed)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_play,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('Sessions',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _startSession(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Start New Session'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (inProgress.isEmpty && completed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No sessions yet. Start one by clicking "Start New Session".',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline),
              ),
            ),
          if (inProgress.isNotEmpty) ...[
            Text('Active',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            ...inProgress.map((s) =>
                SessionCardWidget(session: s, profileId: profile.id)),
          ],
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Completed',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 4),
            ...completed.map((s) =>
                SessionCardWidget(session: s, profileId: profile.id)),
          ],
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context, WidgetRef ref) async {
    // Use .future so we properly await the async provider even on first load
    List<Scenario> scenarios;
    try {
      scenarios = await ref.read(scenarioListProvider.future);
    } catch (_) {
      scenarios = [];
    }

    if (!context.mounted) return;

    if (scenarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No scenarios available. Create one in the Editor first.')),
      );
      return;
    }

    final selected = await showDialog<Scenario>(
      context: context,
      builder: (_) => _ScenarioPickerDialog(scenarios: scenarios),
    );
    if (selected == null) return;

    final now = DateTime.now();
    final session = ScenarioSession(
      id: const Uuid().v4(),
      scenarioId: selected.id,
      scenarioVersion: selected.version,
      scenarioName: selected.name,
      currentQuestionId: selected.questions.isNotEmpty
          ? selected.questions.first.id
          : '',
      startedAt: now,
      updatedAt: now,
    );

    final repo = ref.read(profileRepositoryProvider);
    await repo.upsertSession(profile.id, session);
    ref.invalidate(profileByIdProvider(profile.id));
    ref.invalidate(profileListProvider);

    if (context.mounted) {
      context.go('/profile/${profile.id}/session/${session.id}');
    }
  }
}

class _ScenarioPickerDialog extends StatefulWidget {
  final List<Scenario> scenarios;

  const _ScenarioPickerDialog({required this.scenarios});

  @override
  State<_ScenarioPickerDialog> createState() => _ScenarioPickerDialogState();
}

class _ScenarioPickerDialogState extends State<_ScenarioPickerDialog> {
  String _search = '';

  /// Compares two version strings numerically segment-by-segment.
  /// Returns > 0 if [a] is newer, < 0 if [b] is newer, 0 if equal.
  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  /// Groups all scenarios by id, sorts each group newest-first,
  /// then sorts groups alphabetically by name.
  List<List<Scenario>> _groupScenarios(List<Scenario> all) {
    final map = <String, List<Scenario>>{};
    for (final s in all) {
      map.putIfAbsent(s.id, () => []).add(s);
    }
    return map.values.map((versions) {
      versions.sort((a, b) => _compareVersions(b.version, a.version));
      return versions;
    }).toList()
      ..sort((a, b) => a.first.name.compareTo(b.first.name));
  }

  /// Opens a version-chooser dialog, then closes this dialog with the choice.
  Future<void> _pickVersion(
      BuildContext context, List<Scenario> versions) async {
    final chosen = await showDialog<Scenario>(
      context: context,
      builder: (_) => _VersionPickerDialog(versions: versions),
    );
    if (chosen != null && context.mounted) {
      Navigator.of(context).pop(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _groupScenarios(widget.scenarios);

    final filtered = _search.isEmpty
        ? groups
        : groups
            .where((g) =>
                g.first.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return AlertDialog(
      title: const Text('Select Scenario'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search scenarios...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final group = filtered[i];
                  final latest = group.first;
                  return ListTile(
                    title: Text(latest.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('v${latest.version}'),
                        if (group.length > 1)
                          GestureDetector(
                            onTap: () => _pickVersion(context, group),
                            child: Text(
                              '${group.length} versions available',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                decorationColor: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    // Tapping the tile always picks the latest version.
                    onTap: () => Navigator.of(context).pop(latest),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// A small dialog listing all available versions of a scenario so the user
/// can deliberately pick one other than the latest.
class _VersionPickerDialog extends StatelessWidget {
  final List<Scenario> versions; // already sorted newest-first

  const _VersionPickerDialog({required this.versions});

  @override
  Widget build(BuildContext context) {
    final name = versions.first.name;
    return AlertDialog(
      title: Text(name),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a version to use for this session:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            ...versions.asMap().entries.map((entry) {
              final isLatest = entry.key == 0;
              final s = entry.value;
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.history,
                  size: 18,
                  color: isLatest
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(
                  'v${s.version}',
                  style: TextStyle(
                    fontWeight:
                        isLatest ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: s.author.isNotEmpty ? Text(s.author) : null,
                trailing: isLatest
                    ? Chip(
                        label: const Text('latest'),
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        side: BorderSide.none,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(s),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
