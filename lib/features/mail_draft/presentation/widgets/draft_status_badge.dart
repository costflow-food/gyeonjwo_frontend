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
      DraftStatus.draft => (
        context.palette.ink,
        context.palette.line,
        Icons.edit_note,
      ),
      DraftStatus.sending => (
        const Color(0xFF2F5E8C),
        const Color(0xFFE6EEF6),
        Icons.outgoing_mail,
      ),
      DraftStatus.sent => (
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
        Icons.check,
      ),
      DraftStatus.failed => (danger, dangerTint, Icons.error_outline),
      DraftStatus.unknown => (
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
        Icons.help_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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
