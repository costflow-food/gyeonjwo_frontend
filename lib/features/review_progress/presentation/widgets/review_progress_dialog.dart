import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../domain/review_phase.dart";

/// 검토 진행 창 (`docs/design-ssot.md` 8.2): 모달 틀 + 아래 줄(서버에서 계속
/// 안내 + 닫기). 휴대폰은 아래에서 올라오는 시트 안에 틀 없이 그립니다.
class ReviewProgressDialog extends StatelessWidget {
  const ReviewProgressDialog({
    super.key,
    required this.title,
    required this.outcome,
    required this.body,
    required this.onClose,
    required this.onViewCase,
  });

  final String title;

  /// null while the server is still working.
  final ReviewOutcome? outcome;
  final Widget body;
  final VoidCallback onClose, onViewCase;

  static String footerNote(ReviewOutcome? outcome) => switch (outcome) {
    null => "창을 닫아도 검토는 서버에서 계속됩니다.",
    ReviewOutcome(stopped: true) => "멈춘 이유는 업무에서 확인할 수 있습니다.",
    ReviewOutcome.waitingReply => "회신이 오면 업무 큐에서 이어서 볼 수 있습니다.",
    _ => "다음 단계는 업무에서 진행해 주세요.",
  };

  @override
  Widget build(BuildContext context) => LdsDialog(
    title: "검토 진행",
    subtitle: title,
    maxWidth: 880,
    inSheet: isCompactLayout(context),
    onClose: onClose,
    footerNote: footerNote(outcome),
    actions: [
      LdsButton(
        label: "닫기",
        variant: LdsButtonVariant.outlinedNeutral,
        // 결과가 나왔으면 창을 닫고 그 업무로 갑니다(이전 '업무 보기').
        onPressed: outcome == null ? onClose : onViewCase,
      ),
    ],
    child: body,
  );
}
