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

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.scenarios
        : widget.scenarios
            .where((s) =>
                s.name.toLowerCase().contains(_search.toLowerCase()))
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
                  final s = filtered[i];
                  return ListTile(
                    title: Text(s.name),
                    subtitle: Text('v${s.version} • ${s.questions.length} questions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.of(context).pop(s),
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
