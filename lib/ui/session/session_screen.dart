import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/profile/scenario_session.dart';
import '../../data/models/scenario/answer_destination.dart';
import '../../data/models/scenario/question.dart';
import '../../providers/profile_providers.dart';
import '../../providers/scenario_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/python_providers.dart';
import '../shared/loading_widget.dart';
import '../shared/error_widget.dart';
import '../shared/confirm_dialog.dart';
import 'answer_buttons.dart';
import 'history_sidebar.dart';
import 'question_card.dart';
import 'sub_flow_indicator.dart';

class SessionScreen extends ConsumerWidget {
  final String profileId;
  final String sessionId;

  const SessionScreen({super.key, required this.profileId, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));
    final session = ref.watch(activeSessionProvider(profileId, sessionId));

    return profileAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(error: e),
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('Profile not found.'));
        }
        if (session == null) {
          // Load session from profile
          final s = profile.sessionById(sessionId);
          if (s == null) {
            return const Center(child: Text('Session not found.'));
          }
          return _SessionBody(profileId: profileId, session: s, attachmentPaths: profile.attachmentPaths);
        }
        return _SessionBody(profileId: profileId, session: session, attachmentPaths: profile.attachmentPaths);
      },
    );
  }
}

class _SessionBody extends ConsumerWidget {
  final String profileId;
  final ScenarioSession session;
  final List<String> attachmentPaths;

  const _SessionBody({required this.profileId, required this.session, required this.attachmentPaths});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioAsync = ref.watch(scenarioByIdProvider(session.scenarioId, session.scenarioVersion));

    return scenarioAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(error: e),
      data: (scenario) {
        if (scenario == null) {
          return Center(child: Text('Scenario "${session.scenarioName}" v${session.scenarioVersion} not found.\nIt may have been deleted or not imported.'));
        }

        final question = scenario.questionById(session.currentQuestionId);
        final isCompleted = session.status == SessionStatus.completed;

        // Sub-flow: find resume question title for display
        String? resumeQuestionTitle;
        if (session.subFlowStack.isNotEmpty) {
          final resumeId = session.subFlowStack.last;
          resumeQuestionTitle = scenario.questionById(resumeId)?.title ?? resumeId;
        }

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              _goBack(context, ref);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scenario.name, style: const TextStyle(fontSize: 16)),
                  Text('v${scenario.version}', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              leading: BackButton(onPressed: () => context.go('/profile/$profileId')),
              actions: [
                if (session.history.isNotEmpty) TextButton.icon(onPressed: () => _goBack(context, ref), icon: const Icon(Icons.undo, size: 16), label: const Text('Back')),
                if (isCompleted)
                  Chip(label: const Text('Completed'), backgroundColor: Theme.of(context).colorScheme.tertiaryContainer)
                else
                  TextButton.icon(onPressed: () => _markCompleted(context, ref), icon: const Icon(Icons.check_circle_outline, size: 16), label: const Text('Mark Complete')),
                const SizedBox(width: 8),
              ],
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content
                Expanded(
                  child: isCompleted
                      ? _CompletedView(
                          scenarioName: scenario.name,
                          history: session.history,
                          completionNotes: session.completionNotes,
                          onRestart: () => _restart(context, ref, scenario.questions.first.id),
                        )
                      : question == null
                      ? Center(child: Text('Question "${session.currentQuestionId}" not found in scenario.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (resumeQuestionTitle != null) SubFlowIndicator(resumeQuestionTitle: resumeQuestionTitle),
                              QuestionCard(question: question, profileId: profileId, sessionId: session.id, attachmentPaths: attachmentPaths, storedAnswers: session.storedAnswers),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 12),
                              Text('Your Answer', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8),
                              AnswerButtons(
                                answers: question.answers,
                                suggestedAnswer: ref.watch(pythonRunnerProvider(profileId, session.id, question.id)).suggestedAnswer,
                                enabled: !isCompleted,
                                onAnswerSelected: (answer) => _chooseAnswer(context, ref, answer.label, question.title, answer.destination),
                              ),
                              // if (question.notes.trim().isNotEmpty) ...[
                              //   const SizedBox(height: 16),
                              //   _QuestionNotesHint(question: question),
                              // ],
                            ],
                          ),
                        ),
                ),
                // History sidebar
                HistorySidebar(history: session.history),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _goBack(BuildContext context, WidgetRef ref) async {
    if (session.history.isEmpty) return;
    await ref.read(activeSessionProvider(profileId, session.id).notifier).goBack();
  }

  Future<void> _chooseAnswer(BuildContext context, WidgetRef ref, String label, String questionTitle, AnswerDestination destination) async {
    await ref.read(activeSessionProvider(profileId, session.id).notifier).chooseAnswer(label, questionTitle, destination);
    ref.invalidate(profileByIdProvider(profileId));
  }

  Future<void> _markCompleted(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(context, title: 'Mark Session Complete', message: 'Mark this session as completed?', confirmLabel: 'Complete');
    if (!confirmed) return;

    await ref.read(activeSessionProvider(profileId, session.id).notifier).markCompleted();
  }

  Future<void> _restart(BuildContext context, WidgetRef ref, String firstQuestionId) async {
    // Navigate back to profile to start a new session
    context.go('/profile/$profileId');
  }
}

/// Collapsible panel showing question notes below the answer buttons
/// as a hint/context reminder for the support agent.
class _QuestionNotesHint extends StatefulWidget {
  final Question question;

  const _QuestionNotesHint({required this.question});

  @override
  State<_QuestionNotesHint> createState() => _QuestionNotesHintState();
}

class _QuestionNotesHintState extends State<_QuestionNotesHint> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Question Notes', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: colorScheme.outline),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: MarkdownBody(
                data: widget.question.notes,
                softLineBreak: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(p: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final String scenarioName;
  final List history;
  final String? completionNotes;
  final VoidCallback onRestart;

  const _CompletedView({required this.scenarioName, required this.history, this.completionNotes, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final hasNotes = completionNotes != null && completionNotes!.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 80, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(height: 16),
                Text('Session Complete', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('$scenarioName • ${history.length} questions answered', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
                if (hasNotes) ...[
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 6),
                            Text('Next Steps', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MarkdownBody(data: completionNotes!, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(onPressed: onRestart, icon: const Icon(Icons.arrow_back), label: const Text('Back to Profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
