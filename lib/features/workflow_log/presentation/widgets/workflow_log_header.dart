import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// 설명 줄 + 새로고침. 화면 제목 '실행 로그'는 상단 바에 있습니다.
class WorkflowLogHeader extends StatelessWidget {
  const WorkflowLogHeader({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "업무별 역할·노드·도구 실행과 발송·설정 변경 이력을 확인합니다.",
            style: TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
          ),
        ),
        const SizedBox(width: 16),
        LdsButton(
          label: "새로고침",
          icon: Icons.refresh,
          variant: LdsButtonVariant.outlinedNeutral,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
