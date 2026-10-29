import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// Which quotes and conditions the draft text is based on.
class MailDraftEvidence extends StatelessWidget {
  const MailDraftEvidence({super.key, required this.evidence});
  final List<String> evidence;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "작성 근거",
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (evidence.isEmpty)
          const Text(
            "연결된 근거가 없습니다.",
            style: TextStyle(fontSize: AppFontSizes.body, color: muted),
          ),
        for (final line in evidence)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.subdirectory_arrow_right, size: 14, color: muted),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(fontSize: AppFontSizes.body),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
