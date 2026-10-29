import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/intake_mail.dart";
import "intake_reason_badge.dart";

class IntakeMailRow extends StatelessWidget {
  const IntakeMailRow({
    super.key,
    required this.mail,
    required this.selected,
    required this.onTap,
  });

  final IntakeMail mail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? blush : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
                bottom: const BorderSide(color: line),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mail.subject,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${mail.sender} · ${formatSeoulDateTime(mail.receivedAt)}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 6),
                IntakeReasonBadge(mail.reason),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
