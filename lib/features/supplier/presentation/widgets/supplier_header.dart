import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// Suppliers 위쪽 설명 줄: 화면 제목은 상단 바에 있고, 오른쪽에 새로고침 ·
/// 거래처 등록(7.14b, 외곽선 + 아이콘).
class SupplierHeader extends StatelessWidget {
  const SupplierHeader({
    super.key,
    required this.onRefresh,
    required this.onRegister,
  });

  final VoidCallback onRefresh;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 12,
    children: [
      const Text(
        "업체·연락처·취급 품목·인증·기준자료 출처를 확인합니다.",
        style: TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          LdsButton(
            label: "새로고침",
            icon: Icons.refresh,
            variant: LdsButtonVariant.outlinedNeutral,
            onPressed: onRefresh,
          ),
          LdsButton(
            label: "거래처 등록",
            icon: Icons.add,
            variant: LdsButtonVariant.outlined,
            onPressed: onRegister,
          ),
        ],
      ),
    ],
  );
}
