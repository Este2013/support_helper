import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../data/models/scenario/answer.dart';
import '../../data/models/scenario/answer_destination.dart';
import '../../data/models/scenario/external_link.dart';
import '../../data/models/scenario/question.dart';
import '../../providers/editor_providers.dart';
import 'answer_editor_row.dart';
import 'markdown_editor_widget.dart';

class QuestionEditorTile extends StatefulWidget {
  final Question question;
  final List<String> allQuestionIds;
  final ScenarioEditor notifier;

  const QuestionEditorTile({
    super.key,
    required this.question,
    required this.allQuestionIds,
    required this.notifier,
  });

  @override
  State<QuestionEditorTile> createState() => _QuestionEditorTileState();
}

class _QuestionEditorTileState extends State<QuestionEditorTile> {
  bool _expanded = false;
  late TextEditingController _idCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _scriptCtrl;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.question.id);
    _titleCtrl = TextEditingController(text: widget.question.title);
    _notesCtrl = TextEditingController(text: widget.question.notes);
    _scriptCtrl =
        TextEditingController(text: widget.question.pythonScriptPath ?? '');

    // MarkdownAutoPreview does not fire onChanged — wire up a listener instead
    // so notes edits are persisted to the editor state on every keystroke.
    _notesCtrl.addListener(_saveQuestion);
  }

  @override
  void didUpdateWidget(QuestionEditorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _idCtrl.text = widget.question.id;
    }
  }

  @override
  void dispose() {
    _notesCtrl.removeListener(_saveQuestion);
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _scriptCtrl.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    final updated = widget.question.copyWith(
      id: _idCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text,
      pythonScriptPath: _scriptCtrl.text.trim().isEmpty
          ? null
          : _scriptCtrl.text.trim(),
      clearPythonScript: _scriptCtrl.text.trim().isEmpty,
    );
    widget.notifier.updateQuestion(widget.question.id, updated);
  }

  Future<void> _browseScript() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['py'],
      dialogTitle: 'Select Python Script',
    );
    final path = result?.files.single.path;
    if (path != null) {
      _scriptCtrl.text = path;
      _saveQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: ReorderableDragStartListener(
              index: widget.allQuestionIds.indexOf(widget.question.id),
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(
              widget.question.title.isEmpty ? '(untitled)' : widget.question.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(widget.question.id,
                style: const TextStyle(fontSize: 11)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.question.answers.length} ans',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Question ID',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _saveQuestion(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _saveQuestion(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Notes',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  MarkdownEditorWidget(controller: _notesCtrl),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scriptCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Python Script Path (optional)',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _saveQuestion(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _browseScript,
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Browse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // External links
                  Row(
                    children: [
                      Text('External Links',
                          style: Theme.of(context).textTheme.labelLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => widget.notifier.addExternalLink(
                          widget.question.id,
                          const ExternalLink(
                              label: 'New Link', url: 'https://'),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Link'),
                      ),
                    ],
                  ),
                  ...widget.question.externalLinks
                      .asMap()
                      .entries
                      .map((e) => _ExternalLinkRow(
                            link: e.value,
                            onChanged: (updated) {
                              final links = List<ExternalLink>.from(
                                  widget.question.externalLinks);
                              links[e.key] = updated;
                              widget.notifier.updateQuestion(
                                widget.question.id,
                                widget.question
                                    .copyWith(externalLinks: links),
                              );
                            },
                            onDelete: () => widget.notifier
                                .removeExternalLink(
                                    widget.question.id, e.key),
                          )),
                  const SizedBox(height: 12),
                  // Answers
                  Row(
                    children: [
                      Text('Answers',
                          style: Theme.of(context).textTheme.labelLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => widget.notifier.addAnswer(
                          widget.question.id,
                          const Answer(
                              label: 'New Answer',
                              destination: DestinationEnd()),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Answer'),
                      ),
                    ],
                  ),
                  ...widget.question.answers.asMap().entries.map((e) =>
                      AnswerEditorRow(
                        key: ValueKey(
                            '${widget.question.id}_ans_${e.key}'),
                        answer: e.value,
                        questionIds: widget.allQuestionIds,
                        parentQuestionId: widget.question.id,
                        onChanged: (updated) => widget.notifier
                            .updateAnswer(
                                widget.question.id, e.key, updated),
                        onDelete: () => widget.notifier
                            .deleteAnswer(widget.question.id, e.key),
                      )),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => widget.notifier
                          .deleteQuestion(widget.question.id),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete Question'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExternalLinkRow extends StatefulWidget {
  final ExternalLink link;
  final ValueChanged<ExternalLink> onChanged;
  final VoidCallback onDelete;

  const _ExternalLinkRow({
    required this.link,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ExternalLinkRow> createState() => _ExternalLinkRowState();
}

class _ExternalLinkRowState extends State<_ExternalLinkRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.link.label);
    _urlCtrl = TextEditingController(text: widget.link.url);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => widget.onChanged(
                  ExternalLink(label: _labelCtrl.text, url: _urlCtrl.text)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => widget.onChanged(
                  ExternalLink(label: _labelCtrl.text, url: _urlCtrl.text)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: widget.onDelete,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}
