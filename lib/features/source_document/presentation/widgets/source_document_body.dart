import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';
import '../../domain/source_document.dart';

class SourceDocumentBody extends StatelessWidget {
  const SourceDocumentBody({super.key, required this.document});
  final SourceDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: context.palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              document.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            for (final paragraph in document.paragraphs) ...[
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(children: _highlight(context, paragraph)),
                style: TextStyle(
                  fontSize: 14,
                  height: 2,
                  color: context.palette.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TextSpan> _highlight(BuildContext context, String text) {
    if (document.highlights.isEmpty) return [TextSpan(text: text)];
    final pattern = RegExp(document.highlights.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in pattern.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(end, match.start)));
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            backgroundColor: context.palette.line,
            color: context.palette.ink,
            decoration: TextDecoration.underline,
          ),
        ),
      );
      end = match.end;
    }
    spans.add(TextSpan(text: text.substring(end)));
    return spans;
  }
}
