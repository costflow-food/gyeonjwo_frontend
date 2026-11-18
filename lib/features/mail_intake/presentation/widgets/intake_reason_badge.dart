import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/intake_mail.dart";

/// 확인 이유: 아이콘 14 + 글자 13(바탕 없음).
class IntakeReasonBadge extends StatelessWidget {
  const IntakeReasonBadge(this.reason, {super.key});
  final IntakeReason reason;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (reason) {
      IntakeReason.uncertain => (LdsColors.cautionText, Icons.help_outline),
      IntakeReason.ambiguous => (LdsColors.infoText, Icons.call_split),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(reason.label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}
