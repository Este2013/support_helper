import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/profile/customer_profile.dart';
import '../../data/models/profile/scenario_session.dart';
import '../../providers/profile_providers.dart';
import '../../providers/tab_providers.dart';
import '../shared/confirm_dialog.dart';

class ProfileListTile extends ConsumerWidget {
  final CustomerProfile profile;

  const ProfileListTile({super.key, required this.profile});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessions = profile.sessions
        .where((s) => s.status == SessionStatus.inProgress)
        .length;
    final lastUpdated = _formatDate(profile.updatedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            _initials(profile.name),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          profile.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(lastUpdated),
            if (activeSessions > 0) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('$activeSessions active'),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide.none,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error, size: 20),
              tooltip: 'Delete profile',
              onPressed: () => _deleteProfile(context, ref),
            ),
            const SizedBox(width: 4),
            FilledButton.tonalIcon(
              onPressed: () {
                ref
                    .read(openTabsProvider.notifier)
                    .openProfile(profile.id, profile.name);
                context.go('/profile/${profile.id}');
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open'),
            ),
          ],
        ),
        onTap: () {
          ref
              .read(openTabsProvider.notifier)
              .openProfile(profile.id, profile.name);
          context.go('/profile/${profile.id}');
        },
      ),
    );
  }

  Future<void> _deleteProfile(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Profile',
      message:
          'Delete "${profile.name}"? This will permanently remove all sessions and data for this profile.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.delete(profile.id);
    ref.read(openTabsProvider.notifier).closeTab(profile.id);
    ref.invalidate(profileListProvider);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
