import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/intake_mail.dart";
import "intake_reason_badge.dart";

/// 확인할 메일 카드: 제목 15/700 · 보낸 사람 · 이유 + 받은 시각. 1px 선,
/// 모서리 8, 고른 카드는 주황 2px.
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
    const muted = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LdsRadius.table),
            side: selected
                ? const BorderSide(color: LdsColors.primary, width: 2)
                : const BorderSide(color: LdsColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: LdsColors.canvas,
            child: Padding(
              padding: EdgeInsets.all(selected ? 15 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mail.subject,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mail.sender,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IntakeReasonBadge(mail.reason),
                      Text(formatSeoulDateTime(mail.receivedAt), style: muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
