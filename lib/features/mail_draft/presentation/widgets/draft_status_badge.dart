import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/mail_draft.dart";

class DraftStatusBadge extends StatelessWidget {
  const DraftStatusBadge(this.status, {super.key});
  final DraftStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (status) {
      DraftStatus.draft => (ink, const Color(0xFFF0F1F4), Icons.edit_note),
      DraftStatus.sending => (
        const Color(0xFF347BC8),
        const Color(0xFFDCF2FD),
        Icons.outgoing_mail,
      ),
      DraftStatus.sent => (
        const Color(0xFF4B9138),
        const Color(0xFFE7F5E1),
        Icons.check,
      ),
      DraftStatus.failed => (accent, blush, Icons.error_outline),
      DraftStatus.unknown => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.help_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
          ),
        ],
      ),
    );
  }
}
