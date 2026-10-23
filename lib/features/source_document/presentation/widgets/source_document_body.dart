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
        border: Border.all(color: const Color(0xFFDADCE1)),
        borderRadius: BorderRadius.circular(8),
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
                TextSpan(children: _highlight(paragraph)),
                style: const TextStyle(
                  fontSize: 12,
                  height: 2,
                  color: Color(0xFF72757A),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TextSpan> _highlight(String text) {
    if (document.highlights.isEmpty) return [TextSpan(text: text)];
    final pattern = RegExp(document.highlights.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in pattern.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(end, match.start)));
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            backgroundColor: Color(0xFFE9EAEC),
            color: ink,
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
