import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/preview_button.dart";
import "../../../../shared/workspace_colors.dart";

class SupplierHeader extends StatelessWidget {
  const SupplierHeader({
    super.key,
    required this.onRefresh,
    required this.onRegister,
  });

  final VoidCallback onRefresh;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "거래처",
              style: TextStyle(
                fontSize: AppFontSizes.pageTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "업체·연락처·취급 품목·인증·기준자료 출처를 확인합니다.",
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: context.palette.muted,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PreviewButton("새로고침", icon: Icons.refresh, onPressed: onRefresh),
            PreviewButton(
              "거래처 등록",
              icon: Icons.add_business_outlined,
              filled: true,
              onPressed: onRegister,
            ),
          ],
        ),
      ],
    );
  }
}
