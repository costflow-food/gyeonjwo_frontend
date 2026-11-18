import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// 설명 줄 + 새로고침. 화면 제목 '처리 이력'은 상단 바에 있습니다.
class WorkflowLogHeader extends StatelessWidget {
  /// 설명 줄. 처리 이력 팝업의 부제목으로도 씁니다.
  static const description = "업무별 역할·노드·도구 실행과 발송·설정 변경 이력을 확인합니다.";

  const WorkflowLogHeader({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            description,
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
