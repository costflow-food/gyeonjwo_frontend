import "dart:ui";

import "package:flutter/material.dart";

import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../domain/supplier.dart";
import "widgets/price_history_section.dart";
import "widgets/supplier_evidence_item.dart";
import "widgets/supplier_evidence_supplier.dart";

Future<void> showSupplierEvidenceDialog(
  BuildContext context, {
  required SupplierDetail supplier,
  required SupplierItem item,
}) {
  return showDialog<void>(
    context: context,
    // Full screen on a phone: the dialog paints behind the system bars and
    // LdsDialog's own SafeArea keeps the content clear of them.
    useSafeArea: !isCompactLayout(context),
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: SupplierEvidenceDialog(supplier: supplier, item: item),
    ),
  );
}

/// 거래처·가격 근거 창 (`docs/design-ssot.md` 8.3): 규격 줄 → 가격 이력(요약
/// 3칸 · 참고 견적 표 · 실제 거래 표) → '업체·품목 상세' 접기.
class SupplierEvidenceDialog extends StatelessWidget {
  const SupplierEvidenceDialog({
    super.key,
    required this.supplier,
    required this.item,
  });

  final SupplierDetail supplier;
  final SupplierItem item;

  @override
  Widget build(BuildContext context) {
    return LdsDialog(
      overline: "거래처·견적 근거",
      title: "${supplier.name} · ${item.itemName}",
      maxWidth: 880,
      footerNote: "가격별 적용일·조건·출처를 확인하십시오.",
      actions: [
        LdsButton(
          label: "닫기",
          variant: LdsButtonVariant.outlinedNeutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 모든 줄에 반복되는 규격은 표에서 빼고 여기 한 번(8.3).
          Text(
            [
              item.specification ?? "규격 미확인",
              if (item.unit != null) "단위 ${item.unit}",
              if (item.origin != null) item.origin!,
            ].join(" · "),
            style: const TextStyle(fontSize: 14, color: LdsColors.mutedStrong),
          ),
          const SizedBox(height: 20),
          PriceHistorySection(supplierItemId: item.id),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
            shape: const Border(bottom: BorderSide(color: LdsColors.line)),
            collapsedShape: const Border(
              bottom: BorderSide(color: LdsColors.line),
            ),
            iconColor: LdsColors.title,
            collapsedIconColor: LdsColors.title,
            title: const Text(
              "업체·품목 상세",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LdsColors.ink,
              ),
            ),
            children: [
              SupplierEvidenceSupplier(supplier: supplier),
              const SizedBox(height: 20),
              SupplierEvidenceItem(item: item),
            ],
          ),
        ],
      ),
    );
  }
}
