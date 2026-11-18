import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";

/// Suppliers 상단 바 단추(검색 왼쪽): 새로고침 · 거래처 등록 (7.14b, 외곽선 +
/// 아이콘). 화면 제목은 상단 바에 있어 위쪽 설명 줄은 두지 않습니다.
class SupplierHeader extends StatelessWidget {
  const SupplierHeader({
    super.key,
    required this.onRefresh,
    required this.onRegister,
  });

  final VoidCallback onRefresh;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      LdsButton(
        label: "새로고침",
        icon: Icons.refresh,
        variant: LdsButtonVariant.outlinedNeutral,
        onPressed: onRefresh,
      ),
      const SizedBox(width: 8),
      LdsButton(
        label: "거래처 등록",
        icon: Icons.add,
        variant: LdsButtonVariant.outlined,
        onPressed: onRegister,
      ),
    ],
  );
}
