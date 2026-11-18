import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/workflow_log.dart";

/// Result of one log entry: LdsTag with icon and text, not color alone.
class LogOutcomeBadge extends StatelessWidget {
  const LogOutcomeBadge(this.outcome, {super.key});
  final LogOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (tone, foreground, icon) = switch (outcome) {
      LogOutcome.success => (
        LdsTagTone.success,
        LdsColors.successText,
        Icons.check_circle_outline,
      ),
      LogOutcome.failure => (
        LdsTagTone.error,
        LdsColors.errorText,
        Icons.error_outline,
      ),
      LogOutcome.waiting => (
        LdsTagTone.warning,
        LdsColors.warningText,
        Icons.schedule,
      ),
    };
    return LdsTag(
      outcome.label,
      tone: tone,
      icon: icon,
      foreground: foreground,
    );
  }
}
