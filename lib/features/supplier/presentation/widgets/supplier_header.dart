import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/preview_button.dart";
import "../../../../shared/workspace_colors.dart";

/// 거래처 조회 제목과 새로고침.
class SupplierHeader extends StatelessWidget {
  const SupplierHeader({super.key, required this.onRefresh});

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
              "거래처",
              style: TextStyle(
                fontSize: AppFontSizes.pageTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "업체·연락처·취급 품목·인증·기준자료 출처를 확인합니다.",
              style: TextStyle(fontSize: AppFontSizes.body, color: muted),
            ),
          ],
        ),
        PreviewButton("새로고침", icon: Icons.refresh, onPressed: onRefresh),
      ],
    );
  }
}
