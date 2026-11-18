import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/mail_draft.dart";

/// 초안 상태: 아이콘 14 + 글자 13(바탕 없음). 색은 흰 바탕 위 4.5:1 글자색.
class DraftStatusBadge extends StatelessWidget {
  const DraftStatusBadge(this.status, {super.key});
  final DraftStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      DraftStatus.draft => (LdsColors.title, Icons.schedule),
      DraftStatus.sending => (LdsColors.infoText, Icons.outgoing_mail),
      DraftStatus.sent => (LdsColors.successText, Icons.check_circle_outline),
      DraftStatus.failed => (LdsColors.errorText, Icons.highlight_off),
      DraftStatus.withdrawn => (LdsColors.mutedStrong, Icons.block),
      DraftStatus.unknown => (LdsColors.cautionText, Icons.sync),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(status.label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}
