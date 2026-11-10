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
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
        Icons.help_outline,
      ),
      IntakeReason.ambiguous => (
        const Color(0xFF2F5E8C),
        const Color(0xFFE6EEF6),
        Icons.call_split,
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
            reason.label,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
          ),
        ],
      ),
    );
  }
}
