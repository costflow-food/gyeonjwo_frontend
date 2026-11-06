import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

class MailDraftHeader extends StatelessWidget {
  const MailDraftHeader({
    super.key,
    required this.caseId,
    required this.onClose,
  });

  final String caseId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "메일 초안·발송",
                  style: TextStyle(
                    fontSize: AppFontSizes.dialogTitle,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caseId,
                  style: const TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "닫기",
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
