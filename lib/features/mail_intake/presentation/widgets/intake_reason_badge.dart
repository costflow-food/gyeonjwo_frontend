import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../domain/intake_mail.dart";

class IntakeReasonBadge extends StatelessWidget {
  const IntakeReasonBadge(this.reason, {super.key});
  final IntakeReason reason;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (reason) {
      IntakeReason.uncertain => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.help_outline,
      ),
      IntakeReason.ambiguous => (
        const Color(0xFF347BC8),
        const Color(0xFFDCF2FD),
        Icons.call_split,
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
            reason.label,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
          ),
        ],
      ),
    );
  }
}
