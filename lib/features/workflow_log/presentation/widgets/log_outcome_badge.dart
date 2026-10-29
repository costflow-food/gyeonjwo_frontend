import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/workflow_log.dart";

/// Result of one log entry. Uses text and icon, not color alone.
class LogOutcomeBadge extends StatelessWidget {
  const LogOutcomeBadge(this.outcome, {super.key});
  final LogOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (outcome) {
      LogOutcome.success => (
        const Color(0xFF4B9138),
        const Color(0xFFE7F5E1),
        Icons.check,
      ),
      LogOutcome.failure => (
        accent,
        blush,
        Icons.error_outline,
      ),
      LogOutcome.waiting => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.schedule,
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
            outcome.label,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
          ),
        ],
      ),
    );
  }
}
