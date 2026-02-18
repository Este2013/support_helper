import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/profile/scenario_session.dart';
import '../../providers/profile_providers.dart';
import '../shared/confirm_dialog.dart';

class SessionCardWidget extends ConsumerWidget {
  final ScenarioSession session;
  final String profileId;

  const SessionCardWidget(
      {super.key, required this.session, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = session.status == SessionStatus.inProgress;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.scenarioName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('v${session.scenarioVersion}'),
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                        backgroundColor: colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(isActive: isActive),
                      const SizedBox(width: 8),
                      Text(
                        '${session.history.length} answer${session.history.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(session.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: colorScheme.error, size: 20),
              tooltip: 'Delete session',
              onPressed: () => _deleteSession(context, ref),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: () =>
                  context.go('/profile/$profileId/session/${session.id}'),
              child: Text(isActive ? 'Resume' : 'Review'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSession(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Session',
      message:
          'Delete the "${session.scenarioName}" session? All history for this session will be lost.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.deleteSession(profileId, session.id);
    ref.invalidate(profileByIdProvider(profileId));
    ref.invalidate(profileListProvider);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.play_circle_outline : Icons.check_circle_outline,
            size: 12,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'In Progress' : 'Completed',
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
