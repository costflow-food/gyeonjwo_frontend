import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";

class MailDraftHeader extends StatelessWidget {
  const MailDraftHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              "메일 초안·발송",
              style: TextStyle(
                fontSize: AppFontSizes.dialogTitle,
                fontWeight: FontWeight.w700,
              ),
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
