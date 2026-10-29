import "dart:ui";

import "package:flutter/material.dart";

import "../../../shared/app_font_sizes.dart";
import "../../../shared/workspace_colors.dart";
import "../domain/supplier.dart";
import "widgets/price_history_section.dart";
import "widgets/supplier_evidence_footer.dart";
import "widgets/supplier_evidence_header.dart";
import "widgets/supplier_evidence_item.dart";
import "widgets/supplier_evidence_supplier.dart";

/// SCR-005 거래처·견적 근거 모달을 엽니다 (거래처 조회 맥락).
///
/// Case-specific checklists and current quote terms belong to the SCR-002
/// context and are not shown here.
Future<void> showSupplierEvidenceDialog(
  BuildContext context, {
  required SupplierDetail supplier,
  required SupplierItem item,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: SupplierEvidenceDialog(supplier: supplier, item: item),
    ),
  );
}

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
    return Dialog(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SupplierEvidenceHeader(
              title: "${supplier.name} · ${item.itemName}",
            ),
            const Divider(height: 1, color: line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      [
                        item.specification ?? "규격 미확인",
                        if (item.unit != null) "단위 ${item.unit}",
                        if (item.origin != null) item.origin!,
                      ].join(" · "),
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PriceHistorySection(supplierItemId: item.id),
                    const SizedBox(height: 20),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 12),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor: ink,
                      collapsedIconColor: muted,
                      title: const Text(
                        "업체·품목 상세",
                        style: TextStyle(
                          fontSize: AppFontSizes.bodyLarge,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      children: [
                        SupplierEvidenceSupplier(supplier: supplier),
                        const SizedBox(height: 24),
                        SupplierEvidenceItem(item: item),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: line),
            const SupplierEvidenceFooter(),
          ],
        ),
      ),
    );
  }
}
