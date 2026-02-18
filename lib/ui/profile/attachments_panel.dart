import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../data/models/profile/customer_profile.dart';
import '../../data/services/file_import_export_service.dart';
import '../../providers/profile_providers.dart';
import '../shared/confirm_dialog.dart';

class AttachmentsPanel extends ConsumerWidget {
  final CustomerProfile profile;

  const AttachmentsPanel({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('Attachments',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addAttachments(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Files'),
              ),
            ],
          ),
          if (profile.attachmentPaths.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No attachments',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: profile.attachmentPaths
                  .map((path) => _AttachmentChip(
                        path: path,
                        onRemove: () => _removeAttachment(context, ref, path),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _addAttachments(BuildContext context, WidgetRef ref) async {
    final service = FileImportExportService();
    final paths = await service.pickAttachments();
    if (paths.isEmpty) return;

    final existing = List<String>.from(profile.attachmentPaths);
    for (final path in paths) {
      if (!existing.contains(path)) existing.add(path);
    }

    final repo = ref.read(profileRepositoryProvider);
    await repo.save(profile.copyWith(
        attachmentPaths: existing, updatedAt: DateTime.now()));
    ref.invalidate(profileByIdProvider(profile.id));
  }

  Future<void> _removeAttachment(
      BuildContext context, WidgetRef ref, String path) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Attachment',
      message:
          'Remove "${p.basename(path)}" from this profile? The file itself will not be deleted.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;

    final paths = profile.attachmentPaths.where((p) => p != path).toList();
    final repo = ref.read(profileRepositoryProvider);
    await repo.save(
        profile.copyWith(attachmentPaths: paths, updatedAt: DateTime.now()));
    ref.invalidate(profileByIdProvider(profile.id));
  }
}

class _AttachmentChip extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _AttachmentChip({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final exists = File(path).existsSync();
    return Chip(
      avatar: Icon(
        exists ? Icons.insert_drive_file_outlined : Icons.broken_image_outlined,
        size: 16,
        color: exists
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      label: Text(
        p.basename(path),
        style: TextStyle(
          color: exists
              ? null
              : Theme.of(context).colorScheme.error,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
    );
  }
}
