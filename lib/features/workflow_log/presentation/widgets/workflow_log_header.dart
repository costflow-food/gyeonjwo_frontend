import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/preview_button.dart";
import "../../../../shared/workspace_colors.dart";

class WorkflowLogHeader extends StatelessWidget {
  const WorkflowLogHeader({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "실행 로그",
              style: TextStyle(
                fontSize: AppFontSizes.pageTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "업무별 역할·노드·도구 실행과 발송·설정 변경 이력을 확인합니다.",
              style: TextStyle(fontSize: AppFontSizes.body, color: muted),
            ),
          ],
        ),
        PreviewButton("새로고침", icon: Icons.refresh, onPressed: onRefresh),
      ],
    );
  }
}
