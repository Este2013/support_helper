import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/scenario/answer.dart';
import '../../data/models/scenario/answer_destination.dart';

class AnswerButtons extends StatelessWidget {
  final List<Answer> answers;
  final String? suggestedAnswer;
  final bool enabled;
  final void Function(Answer answer) onAnswerSelected;

  const AnswerButtons({
    super.key,
    required this.answers,
    required this.suggestedAnswer,
    required this.enabled,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (answers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No answers configured for this question.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: answers.map((answer) {
        final isSuggested = suggestedAnswer != null &&
            answer.label.toLowerCase() ==
                suggestedAnswer!.toLowerCase();
        return _AnswerButton(
          answer: answer,
          isSuggested: isSuggested,
          enabled: enabled,
          onTap: () => onAnswerSelected(answer),
        );
      }).toList(),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final Answer answer;
  final bool isSuggested;
  final bool enabled;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.answer,
    required this.isSuggested,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSubFlow = answer.destination is DestinationSubFlow;
    final isEnd = answer.destination is DestinationEnd;

    Widget button;
    if (isSuggested) {
      button = FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.suggestedAnswerBorder,
        ),
        child: _ButtonContent(
          answer: answer,
          isSubFlow: isSubFlow,
          isEnd: isEnd,
          isSuggested: true,
        ),
      );
    } else {
      button = OutlinedButton(
        onPressed: enabled ? onTap : null,
        child: _ButtonContent(
          answer: answer,
          isSubFlow: isSubFlow,
          isEnd: isEnd,
          isSuggested: false,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: button,
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final Answer answer;
  final bool isSubFlow;
  final bool isEnd;
  final bool isSuggested;

  const _ButtonContent({
    required this.answer,
    required this.isSubFlow,
    required this.isEnd,
    required this.isSuggested,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isSuggested) ...[
            const Icon(Icons.auto_awesome, size: 16),
            const SizedBox(width: 6),
          ],
          if (isSubFlow) ...[
            const Icon(Icons.call_split, size: 16),
            const SizedBox(width: 6),
          ],
          if (isEnd) ...[
            const Icon(Icons.check_circle_outline, size: 16),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (answer.notes != null && answer.notes!.isNotEmpty)
                  Text(
                    answer.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSuggested
                          ? Colors.white70
                          : Theme.of(context).colorScheme.outline,
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
