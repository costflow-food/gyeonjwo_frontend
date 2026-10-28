import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// Shown when Gmail read permission is missing; automatic receiving is off.
class GmailReadNotice extends StatelessWidget {
  const GmailReadNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: blush,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        const Icon(Icons.mark_email_unread_outlined, size: 18, color: accent),
        const Text(
          "Gmail 읽기 권한이 없어 메일 자동 수신이 꺼져 있어요.",
          style: TextStyle(fontSize: AppFontSizes.body, color: ink),
        ),
        TextButton(
          onPressed: () => context.go("/login/permissions"),
          child: const Text("권한 다시 선택하기"),
        ),
      ],
    ),
  );
}
