import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/scenario/answer.dart';
import '../../data/models/scenario/answer_destination.dart';
import '../../data/models/scenario/question.dart';
import '../../data/models/scenario/scenario.dart';
import '../../data/services/file_import_export_service.dart';
import '../../providers/editor_providers.dart';
import '../../providers/scenario_providers.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import 'question_editor_tile.dart';

class ScenarioEditorScreen extends ConsumerWidget {
  final String? scenarioId;
  final String? scenarioVersion;

  const ScenarioEditorScreen(
      {super.key, required this.scenarioId, required this.scenarioVersion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scenarioId == null) {
      // New scenario
      final now = DateTime.now();
      final blank = Scenario(
        id: 'new-scenario',
        name: 'New Scenario',
        version: '1.0',
        createdAt: now,
        updatedAt: now,
      );
      return _EditorBody(initialScenario: blank);
    }

    final scenarioAsync =
        ref.watch(scenarioByIdProvider(scenarioId!, scenarioVersion!));
    return scenarioAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(error: e),
      data: (scenario) {
        if (scenario == null) {
          return const Center(child: Text('Scenario not found.'));
        }
        return _EditorBody(initialScenario: scenario);
      },
    );
  }
}

class _EditorBody extends ConsumerWidget {
  final Scenario initialScenario;

  const _EditorBody({required this.initialScenario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState =
        ref.watch(scenarioEditorProvider(initialScenario));
    final notifier =
        ref.read(scenarioEditorProvider(initialScenario).notifier);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            notifier.save(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: Text(editorState.draft.name,
                      overflow: TextOverflow.ellipsis),
                ),
                if (editorState.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: const Text('Unsaved'),
                      padding: EdgeInsets.zero,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      side: BorderSide.none,
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (editorState.validationError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    editorState.validationError!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextButton.icon(
                onPressed: editorState.isSaving
                    ? null
                    : () => _export(context, ref, editorState.draft),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Export'),
              ),
              FilledButton.icon(
                onPressed: editorState.isSaving
                    ? null
                    : () async {
                        final ok = await notifier.save();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Scenario saved.')),
                          );
                        }
                      },
                icon: editorState.isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta panel
              SizedBox(
                width: 260,
                child: _MetaPanel(
                  draft: editorState.draft,
                  notifier: notifier,
                ),
              ),
              const VerticalDivider(width: 1),
              // Questions list
              Expanded(
                child: _QuestionList(
                  draft: editorState.draft,
                  notifier: notifier,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, Scenario scenario) async {
    final service = FileImportExportService();
    final path = await service.pickJsonFileToExport(
        '${scenario.id}_v${scenario.version}.json');
    if (path == null) return;
    final repo = ref.read(scenarioRepositoryProvider);
    await repo.exportToFile(scenario, path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    }
  }
}

class _MetaPanel extends StatefulWidget {
  final Scenario draft;
  final ScenarioEditor notifier;

  const _MetaPanel({required this.draft, required this.notifier});

  @override
  State<_MetaPanel> createState() => _MetaPanelState();
}

class _MetaPanelState extends State<_MetaPanel> {
  late TextEditingController _idCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _versionCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.draft.id);
    _nameCtrl = TextEditingController(text: widget.draft.name);
    _versionCtrl = TextEditingController(text: widget.draft.version);
    _authorCtrl = TextEditingController(text: widget.draft.author);
    _descCtrl = TextEditingController(text: widget.draft.description);
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _versionCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.notifier.updateMeta(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      version: _versionCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
    );
    // ID is not part of updateMeta — handle separately if needed
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scenario Info',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _idCtrl,
            decoration: const InputDecoration(
              labelText: 'ID (filename-safe)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => widget.notifier.updateMeta(id: v.trim()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _versionCtrl,
            decoration: const InputDecoration(
              labelText: 'Version',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorCtrl,
            decoration: const InputDecoration(
              labelText: 'Author',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  final Scenario draft;
  final ScenarioEditor notifier;

  const _QuestionList({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final questionIds = draft.questions.map((q) => q.id).toList();

    return Scaffold(
      body: draft.questions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No questions yet. Add one below.'),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: draft.questions.length,
              onReorderItem: (oldIndex, newIndex) =>
                  notifier.reorderQuestions(oldIndex, newIndex),
              itemBuilder: (_, i) {
                final q = draft.questions[i];
                return QuestionEditorTile(
                  key: ValueKey(q.id),
                  question: q,
                  allQuestionIds: questionIds,
                  notifier: notifier,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final preset = await showDialog<Question>(
            context: context,
            builder: (_) => const _QuestionPresetDialog(),
          );
          if (preset != null) {
            notifier.addQuestion(preset);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
    );
  }
}

/// Dialog for picking a question preset when adding a new question.
class _QuestionPresetDialog extends StatelessWidget {
  const _QuestionPresetDialog();

  String _newId() => 'q_${const Uuid().v4().substring(0, 8)}';

  Question _blank() => Question(
        id: _newId(),
        title: 'New Question',
      );

  Question _yesNo() => Question(
        id: _newId(),
        title: 'New Yes/No Question',
        answers: const [
          Answer(label: 'Yes', destination: DestinationEnd()),
          Answer(label: 'No', destination: DestinationEnd()),
        ],
      );

  Question _windowsMac() => Question(
        id: _newId(),
        title: 'What OS is the customer using?',
        answers: const [
          Answer(label: 'Windows', destination: DestinationEnd()),
          Answer(label: 'macOS', destination: DestinationEnd()),
          Answer(label: 'Linux', destination: DestinationEnd()),
        ],
      );

  Question _workedOrNot() => Question(
        id: _newId(),
        title: 'Did that fix the issue?',
        answers: const [
          Answer(label: 'It worked!', destination: DestinationEnd()),
          Answer(label: "It didn't work", destination: DestinationEnd()),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final presets = [
      (
        icon: Icons.article_outlined,
        label: 'Blank Question',
        description: 'Start from scratch',
        build: _blank,
      ),
      (
        icon: Icons.thumbs_up_down_outlined,
        label: 'Yes / No',
        description: 'Two answer buttons: Yes and No',
        build: _yesNo,
      ),
      (
        icon: Icons.computer,
        label: 'Windows / macOS / Linux',
        description: 'OS selection question',
        build: _windowsMac,
      ),
      (
        icon: Icons.check_circle_outline,
        label: 'It worked / It didn\'t',
        description: 'Follow-up resolution check',
        build: _workedOrNot,
      ),
    ];

    return AlertDialog(
      title: const Text('Add Question'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a preset to pre-fill the question:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            ...presets.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(p.icon,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(p.label,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.description,
                        style: Theme.of(context).textTheme.bodySmall),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color:
                              Theme.of(context).colorScheme.outlineVariant),
                    ),
                    onTap: () => Navigator.of(context).pop(p.build()),
                  ),
                )),
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
