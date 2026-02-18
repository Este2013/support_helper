import 'package:flutter/material.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';

class MarkdownEditorWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final double minHeight;

  const MarkdownEditorWidget({
    super.key,
    required this.controller,
    this.hintText = 'Notes (markdown)...',
    this.minHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: MarkdownAutoPreview(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hintText,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
