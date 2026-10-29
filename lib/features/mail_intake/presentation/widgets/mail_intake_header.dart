import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

class MailIntakeHeader extends StatelessWidget {
  const MailIntakeHeader({
    super.key,
    required this.totalPending,
    required this.onRefresh,
    required this.onClose,
  });

  final int? totalPending;
  final VoidCallback onRefresh;
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
                  "접수·연결 확인",
                  style: TextStyle(
                    fontSize: AppFontSizes.dialogTitle,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPending == null
                      ? "판단 불가·연결 모호 메일"
                      : "판단 불가·연결 모호 메일 $totalPending건",
                  style: const TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "새로고침",
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
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
