import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import '../../data/models/profile/customer_profile.dart';
import '../../providers/profile_providers.dart';
import '../../providers/tab_providers.dart';

class ProfileHeaderWidget extends ConsumerStatefulWidget {
  final CustomerProfile profile;

  const ProfileHeaderWidget({super.key, required this.profile});

  @override
  ConsumerState<ProfileHeaderWidget> createState() =>
      _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends ConsumerState<ProfileHeaderWidget> {
  bool _editingName = false;
  /// True once the user has modified the notes controller text.
  /// Drives visibility of the Save / Cancel row.
  bool _notesDirty = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _notesCtrl = TextEditingController(text: widget.profile.notes);
    _notesCtrl.addListener(_onNotesChanged);
  }

  void _onNotesChanged() {
    final dirty = _notesCtrl.text != widget.profile.notes;
    if (dirty != _notesDirty) setState(() => _notesDirty = dirty);
  }

  @override
  void didUpdateWidget(ProfileHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.name != widget.profile.name) {
      _nameCtrl.text = widget.profile.name;
    }
    if (oldWidget.profile.notes != widget.profile.notes) {
      _notesCtrl.text = widget.profile.notes;
      // Reset dirty flag — the external update is now the baseline.
      setState(() => _notesDirty = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == widget.profile.name) {
      setState(() => _editingName = false);
      return;
    }
    final repo = ref.read(profileRepositoryProvider);
    final updated = widget.profile.copyWith(
        name: name, updatedAt: DateTime.now());
    await repo.save(updated);
    ref.invalidate(profileByIdProvider(widget.profile.id));
    ref.invalidate(profileListProvider);
    ref
        .read(openTabsProvider.notifier)
        .updateDisplayName(widget.profile.id, name);
    setState(() => _editingName = false);
  }

  Future<void> _saveNotes() async {
    final notes = _notesCtrl.text;
    if (notes == widget.profile.notes) {
      setState(() => _notesDirty = false);
      return;
    }
    final repo = ref.read(profileRepositoryProvider);
    final updated =
        widget.profile.copyWith(notes: notes, updatedAt: DateTime.now());
    await repo.save(updated);
    ref.invalidate(profileByIdProvider(widget.profile.id));
    ref.invalidate(profileListProvider);
    // _notesDirty will be cleared by didUpdateWidget when the new profile
    // propagates back, but clear it immediately for snappy UI feedback.
    setState(() => _notesDirty = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row
          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: _editingName
                    ? TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: UnderlineInputBorder(),
                        ),
                        onSubmitted: (_) => _saveName(),
                        onEditingComplete: _saveName,
                      )
                    : GestureDetector(
                        onDoubleTap: () =>
                            setState(() => _editingName = true),
                        child: Text(
                          widget.profile.name,
                          style:
                              Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
              ),
              if (_editingName) ...[
                IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveName),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _nameCtrl.text = widget.profile.name;
                      setState(() => _editingName = false);
                    }),
              ] else
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => setState(() => _editingName = true),
                  tooltip: 'Edit name',
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Notes — always show MarkdownAutoPreview so the first click
          // immediately enters edit mode (the widget manages its own
          // preview ↔ edit toggle internally via FocusableActionDetector).
          MarkdownAutoPreview(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Customer notes (markdown)...',
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          if (_notesDirty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _notesCtrl.text = widget.profile.notes;
                    // _onNotesChanged listener will clear _notesDirty.
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: _saveNotes, child: const Text('Save Notes')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
