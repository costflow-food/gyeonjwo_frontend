import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "certification_badge.dart";
import "supplier_fact.dart";

/// One handled item. Mail quotes and receipt-backed purchases stay separate.
class SupplierItemCard extends StatelessWidget {
  const SupplierItemCard({
    super.key,
    required this.item,
    required this.onOpenEvidence,
  });

  final SupplierItem item;
  final VoidCallback onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final quote = item.latestReferenceQuote;
    final purchase = item.lastPurchase;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: AppFontSizes.documentTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.specification ?? "규격 미확인",
                      style: const TextStyle(
                        fontSize: AppFontSizes.secondary,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onOpenEvidence,
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text(
                  "근거·가격 이력",
                  style: TextStyle(fontSize: AppFontSizes.buttonSmall),
                ),
                style: TextButton.styleFrom(foregroundColor: ink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SupplierFact("단위", item.unit, width: 90),
              SupplierFact("박스당 수량", item.unitsPerBox, width: 90),
              SupplierFact(
                "박스당 중량",
                item.weightPerBox == null ? null : "${item.weightPerBox}kg",
                width: 90,
              ),
              SupplierFact("원산지", item.origin, width: 150),
            ],
          ),
          const SizedBox(height: 14),
          if (item.certifications.isEmpty)
            const Text(
              "인증 정보 미확인",
              style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final certification in item.certifications)
                  CertificationBadge(certification),
              ],
            ),
          if (item.notes != null) ...[
            const SizedBox(height: 14),
            Text(
              "품목 비고 · ${item.notes}",
              style: const TextStyle(fontSize: AppFontSizes.body, height: 1.5),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SupplierFact(
                "최근 참고 견적 (메일)",
                quote == null
                    ? null
                    : "${formatDecimal(quote.unitPrice)}원/${quote.unit}"
                          "${quote.effectiveFrom == null ? "" : " · ${formatIsoDate(quote.effectiveFrom!)} 적용"}",
                width: 220,
              ),
              SupplierFact(
                "마지막 실거래 (증빙)",
                purchase == null
                    ? null
                    : "${formatDecimal(purchase.unitPrice)}원/${purchase.unit}"
                          " · ${formatIsoDate(purchase.transactionDate)}",
                width: 220,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
