import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/profile/customer_profile.dart';
import '../../providers/profile_providers.dart';

class NewProfileDialog extends ConsumerStatefulWidget {
  const NewProfileDialog({super.key});

  @override
  ConsumerState<NewProfileDialog> createState() => _NewProfileDialogState();
}

class _NewProfileDialogState extends ConsumerState<NewProfileDialog> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);

    final now = DateTime.now();
    final profile = CustomerProfile(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    final repo = ref.read(profileRepositoryProvider);
    await repo.save(profile);
    ref.invalidate(profileListProvider);

    if (mounted) Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Customer Profile'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Customer Name',
          hintText: 'e.g. Contoso Ltd. - John Doe',
        ),
        onSubmitted: (_) => _create(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _creating ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
