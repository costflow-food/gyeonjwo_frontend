import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";

/// 거래처 출처 라벨(4.1 weak): 직접 등록 · 웹 확인.
class SupplierSourceBadge extends StatelessWidget {
  const SupplierSourceBadge(this.sourceType, {super.key});
  final SupplierSourceType sourceType;

  @override
  Widget build(BuildContext context) => switch (sourceType) {
    SupplierSourceType.registered => LdsTag(
      sourceType.label,
      tone: LdsTagTone.success,
      icon: Icons.verified_outlined,
      foreground: LdsColors.successText,
    ),
    SupplierSourceType.verifiedWeb => LdsTag(
      sourceType.label,
      tone: LdsTagTone.progressing,
      icon: Icons.language,
    ),
  };
}
