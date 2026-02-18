import 'package:flutter/material.dart';
import '../../data/models/scenario/answer.dart';
import '../../data/models/scenario/answer_destination.dart';
import '../../data/models/scenario/question.dart';

class AnswerEditorRow extends StatefulWidget {
  final Answer answer;
  /// All questions in the scenario (for "Leads to" dropdown — shows id + title).
  final List<Question> allQuestions;
  /// The ID of the question that owns this answer (for self-loop detection).
  final String parentQuestionId;
  final ValueChanged<Answer> onChanged;
  final VoidCallback onDelete;

  const AnswerEditorRow({
    super.key,
    required this.answer,
    required this.allQuestions,
    required this.parentQuestionId,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<AnswerEditorRow> createState() => _AnswerEditorRowState();
}

class _AnswerEditorRowState extends State<AnswerEditorRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _subFlowFirstCtrl;
  late TextEditingController _subFlowResumeCtrl;
  late TextEditingController _endNotesCtrl;
  late String _destType;
  late String? _destQuestionId;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.answer.label);
    _notesCtrl = TextEditingController(text: widget.answer.notes ?? '');

    final dest = widget.answer.destination;
    if (dest is DestinationQuestion) {
      _destType = 'question';
      _destQuestionId = dest.questionId;
      _subFlowFirstCtrl = TextEditingController();
      _subFlowResumeCtrl = TextEditingController();
      _endNotesCtrl = TextEditingController();
    } else if (dest is DestinationSubFlow) {
      _destType = 'subflow';
      _destQuestionId = null;
      _subFlowFirstCtrl = TextEditingController(text: dest.firstQuestionId);
      _subFlowResumeCtrl = TextEditingController(text: dest.resumeQuestionId);
      _endNotesCtrl = TextEditingController();
    } else if (dest is DestinationEndWithNotes) {
      _destType = 'end_with_notes';
      _destQuestionId = null;
      _subFlowFirstCtrl = TextEditingController();
      _subFlowResumeCtrl = TextEditingController();
      _endNotesCtrl = TextEditingController(text: dest.notes);
    } else {
      _destType = 'end';
      _destQuestionId = null;
      _subFlowFirstCtrl = TextEditingController();
      _subFlowResumeCtrl = TextEditingController();
      _endNotesCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _notesCtrl.dispose();
    _subFlowFirstCtrl.dispose();
    _subFlowResumeCtrl.dispose();
    _endNotesCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    AnswerDestination dest;
    switch (_destType) {
      case 'question':
        dest = DestinationQuestion(questionId: _destQuestionId ?? '');
      case 'subflow':
        dest = DestinationSubFlow(
          firstQuestionId: _subFlowFirstCtrl.text.trim(),
          resumeQuestionId: _subFlowResumeCtrl.text.trim(),
        );
      case 'end_with_notes':
        dest = DestinationEndWithNotes(notes: _endNotesCtrl.text);
      default:
        dest = const DestinationEnd();
    }

    widget.onChanged(Answer(
      label: _labelCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      destination: dest,
    ));
  }

  /// Returns the display string for a question: "id — Title".
  String _questionLabel(Question q) =>
      q.title.isEmpty ? q.id : '${q.id}  —  ${q.title}';

  @override
  Widget build(BuildContext context) {
    final questionIds = widget.allQuestions.map((q) => q.id).toList();

    // Resolve the currently selected destination question ID against the live list.
    final resolvedDestId = questionIds.contains(_destQuestionId)
        ? _destQuestionId
        : (questionIds.isNotEmpty ? questionIds.first : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label + delete ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Answer Label',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete answer',
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Answer notes ──────────────────────────────────────────────
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Answer Notes (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),

            // ── Destination type ──────────────────────────────────────────
            Row(
              children: [
                const Text('Leads to: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _destType,
                  items: const [
                    DropdownMenuItem(
                        value: 'question', child: Text('Question')),
                    DropdownMenuItem(value: 'end', child: Text('End')),
                    DropdownMenuItem(
                        value: 'end_with_notes',
                        child: Text('End with Notes')),
                    DropdownMenuItem(
                        value: 'subflow', child: Text('Sub-flow')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _destType = v;
                      if (v == 'question' && widget.allQuestions.isNotEmpty) {
                        _destQuestionId ??= widget.allQuestions.first.id;
                      }
                    });
                    _emit();
                  },
                ),
                // ── Question picker (shown when dest == 'question') ────────
                if (_destType == 'question') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: widget.allQuestions.isEmpty
                        ? const Text('No questions available',
                            style: TextStyle(fontSize: 13))
                        : DropdownButton<String>(
                            isExpanded: true,
                            value: resolvedDestId,
                            hint: const Text('Select question'),
                            items: widget.allQuestions
                                .map((q) => DropdownMenuItem<String>(
                                      value: q.id,
                                      child: Text(
                                        _questionLabel(q),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _destQuestionId = v);
                              _emit();
                            },
                          ),
                  ),
                ],
              ],
            ),

            // ── Self-loop warning ─────────────────────────────────────────
            if (_destType == 'question' &&
                _destQuestionId == widget.parentQuestionId) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 6),
                    Text(
                      'Self-loop: this answer leads back to the same question.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Sub-flow fields ───────────────────────────────────────────
            if (_destType == 'subflow') ...[
              const SizedBox(height: 8),
              _SubFlowQuestionField(
                label: 'First Question',
                controller: _subFlowFirstCtrl,
                allQuestions: widget.allQuestions,
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 8),
              _SubFlowQuestionField(
                label: 'Resume Question',
                controller: _subFlowResumeCtrl,
                allQuestions: widget.allQuestions,
                onChanged: (_) => _emit(),
              ),
            ],

            // ── End-with-notes textarea ───────────────────────────────────
            if (_destType == 'end_with_notes') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _endNotesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'End Screen Notes (markdown)',
                  hintText:
                      'e.g. "Offer an exchange and follow KB-1234 procedure..."',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _emit(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-flow question field: dropdown picker + manual text fallback
// ---------------------------------------------------------------------------

/// A row that lets the user pick a question from the dropdown (showing
/// "id — Title") or type a raw question ID if the list is empty.
class _SubFlowQuestionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<Question> allQuestions;
  final ValueChanged<String> onChanged;

  const _SubFlowQuestionField({
    required this.label,
    required this.controller,
    required this.allQuestions,
    required this.onChanged,
  });

  String _questionLabel(Question q) =>
      q.title.isEmpty ? q.id : '${q.id}  —  ${q.title}';

  @override
  Widget build(BuildContext context) {
    if (allQuestions.isEmpty) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label ID',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      );
    }

    final questionIds = allQuestions.map((q) => q.id).toList();
    final resolved = questionIds.contains(controller.text)
        ? controller.text
        : questionIds.first;

    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: resolved,
            items: allQuestions
                .map((q) => DropdownMenuItem<String>(
                      value: q.id,
                      child: Text(
                        _questionLabel(q),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                controller.text = v;
                onChanged(v);
              }
            },
          ),
        ),
      ],
    );
  }
}
