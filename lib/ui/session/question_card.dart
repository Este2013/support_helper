import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/python/python_input.dart';
import '../../data/models/scenario/question.dart';
import '../../providers/python_providers.dart';
import '../shared/markdown_view.dart';
import 'python_result_panel.dart';

class QuestionCard extends ConsumerWidget {
  final Question question;
  final String profileId;
  final String sessionId;
  final List<String> attachmentPaths;
  final Map<String, String> storedAnswers;

  const QuestionCard({
    super.key,
    required this.question,
    required this.profileId,
    required this.sessionId,
    required this.attachmentPaths,
    required this.storedAnswers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pythonState = ref.watch(
        pythonRunnerProvider(profileId, sessionId, question.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question title
        Text(
          question.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),

        // Notes
        if (question.notes.trim().isNotEmpty) ...[
          MarkdownView(data: question.notes),
          const SizedBox(height: 12),
        ],

        // External links
        if (question.externalLinks.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: question.externalLinks.map((link) {
              return ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 14),
                label: Text(link.label),
                onPressed: () async {
                  final uri = Uri.tryParse(link.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Python script button
        if (question.pythonScriptPath != null) ...[
          OutlinedButton.icon(
            onPressed: pythonState.isRunning
                ? null
                : () {
                    final input = PythonScriptInput(
                      attachments: attachmentPaths,
                      storedAnswers: storedAnswers,
                    );
                    ref
                        .read(pythonRunnerProvider(
                                profileId, sessionId, question.id)
                            .notifier)
                        .run(question.pythonScriptPath!, input);
                  },
            icon: pythonState.isRunning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.terminal, size: 16),
            label: Text(
                pythonState.isRunning ? 'Running...' : 'Run Script'),
          ),
          const SizedBox(height: 12),
        ],

        // Python result panel
        if (pythonState.hasResult || pythonState.isRunning)
          PythonResultPanel(
            state: pythonState,
            onDismiss: () => ref
                .read(pythonRunnerProvider(
                        profileId, sessionId, question.id)
                    .notifier)
                .clear(),
          ),
      ],
    );
  }
}
