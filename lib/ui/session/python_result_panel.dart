import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/python_providers.dart';
import '../shared/markdown_view.dart';

class PythonResultPanel extends StatelessWidget {
  final PythonRunState state;
  final VoidCallback onDismiss;

  const PythonResultPanel(
      {super.key, required this.state, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (state.isRunning) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Running script...'),
          ],
        ),
      );
    }

    if (!state.hasResult) return const SizedBox.shrink();

    final isError = state.error != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : AppColors.suggestedAnswerHighlight,
        border: Border.all(
          color: isError
              ? colorScheme.error
              : AppColors.suggestedAnswerBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.auto_awesome,
                size: 18,
                color: isError
                    ? colorScheme.error
                    : AppColors.suggestedAnswerBorder,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isError ? 'Script Error' : 'Script Suggestion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isError
                        ? colorScheme.error
                        : AppColors.suggestedAnswerBorder,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (isError) ...[
            const SizedBox(height: 8),
            Text(state.error!,
                style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontFamily: 'monospace')),
          ] else ...[
            if (state.suggestedAnswer != null) ...[
              const SizedBox(height: 8),
              Text(
                'Suggested: ${state.suggestedAnswer}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.suggestedAnswerBorder,
                ),
              ),
            ],
            if (state.notes != null) ...[
              const SizedBox(height: 8),
              MarkdownView(data: state.notes!),
            ],
          ],
        ],
      ),
    );
  }
}
