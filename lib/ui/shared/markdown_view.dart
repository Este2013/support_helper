import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownView extends StatelessWidget {
  final String data;
  final bool shrinkWrap;

  const MarkdownView({
    super.key,
    required this.data,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) return const SizedBox.shrink();
    return MarkdownBody(
      data: data,
      shrinkWrap: shrinkWrap,
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }
}
