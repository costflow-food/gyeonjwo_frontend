import 'package:flutter/material.dart';

import '../../../../shared/lds_colors.dart';
import '../../../../shared/widgets/lds/lds.dart';
import '../../domain/source_document.dart';

/// 본문 상자: 제목 17/700, 문단 15px 줄간격 1.6. 근거 글자는 밑줄.
class SourceDocumentBody extends StatelessWidget {
  const SourceDocumentBody({super.key, required this.document});
  final SourceDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              document.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: LdsColors.ink,
              ),
            ),
            for (final paragraph in document.paragraphs) ...[
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(children: _highlight(paragraph)),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: LdsColors.title,
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
            color: LdsColors.ink,
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
