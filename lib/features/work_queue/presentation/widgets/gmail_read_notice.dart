import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/widgets/lds/lds.dart";

/// Gmail 읽기 권한 없음: 상태 안내 띠(LdsNotice). Tasks·Dashboard 콘텐츠 첫 줄.
class GmailReadNotice extends StatelessWidget {
  const GmailReadNotice({super.key});

  @override
  Widget build(BuildContext context) => LdsNotice(
    tone: LdsNoticeTone.warning,
    icon: Icons.mark_email_unread_outlined,
    message: "Gmail 읽기 권한이 없어 메일 자동 수신이 꺼져 있습니다.",
    action: LdsButton(
      label: "권한 다시 선택하기",
      size: LdsButtonSize.small,
      variant: LdsButtonVariant.outlinedNeutral,
      onPressed: () => context.go("/login/permissions"),
    ),
  );
}
