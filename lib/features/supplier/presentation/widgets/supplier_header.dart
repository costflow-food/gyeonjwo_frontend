import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// Suppliers 맨 위 줄 (7.14b): 왼쪽 화면 설명, 오른쪽 '새로고침' 다음
/// '거래처 등록'(등록만 + 아이콘). 좁으면 단추가 설명 아래로 내려갑니다.
/// 단추는 Invoices 필터·정렬 단추와 같은 모양·글자(outlinedPlain).
class SupplierHeader extends StatelessWidget {
  const SupplierHeader({
    super.key,
    required this.onRefresh,
    required this.onRegister,
  });

  static const lead = "업체·연락처·취급 품목·인증·기준자료 출처를 확인합니다.";

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
        lead,
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          letterSpacing: -.3,
          color: LdsColors.muted,
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LdsButton(
            label: "새로고침",
            variant: LdsButtonVariant.outlinedPlain,
            onPressed: onRefresh,
          ),
          const SizedBox(width: 8),
          LdsButton(
            label: "거래처 등록",
            icon: Icons.add,
            variant: LdsButtonVariant.outlinedPlain,
            onPressed: onRegister,
          ),
        ],
      ),
    ],
  );
}
