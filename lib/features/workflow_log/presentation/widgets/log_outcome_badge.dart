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
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
        Icons.check,
      ),
      LogOutcome.failure => (danger, dangerTint, Icons.error_outline),
      LogOutcome.waiting => (
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
        Icons.schedule,
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
            outcome.label,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
          ),
        ],
      ),
    );
  }
}
