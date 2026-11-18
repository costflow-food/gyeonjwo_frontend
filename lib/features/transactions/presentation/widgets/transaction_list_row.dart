import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/list_detail_layout.dart";
import "../../domain/transaction_listing.dart";
import "../transaction_format.dart";
import "price_change_text.dart";

/// 확정 거래 한 줄(두 줄 행).
///
/// 1줄 = 품목(15/700) + 거래처(13 `#6B7583`) + 오른쪽 단가 '5,400원/kg'(보통
/// 굵기). 2줄 = '2026.10.18 · 1,000kg'(13 `#6B7583`) + 오른쪽 직전 대비.
class TransactionListRow extends StatelessWidget {
  const TransactionListRow({
    super.key,
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final TransactionRow row;
  final bool selected;
  final VoidCallback onTap;

  static const _muted = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: LdsColors.muted,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final record = row.record;
    final tooltip = changeTooltip(row.change);
    return ListSelectableRow(
      selected: selected,
      onTap: onTap,
      semanticLabel: [
        "${dateText(record)} ${record.itemName} ${record.supplierName} "
            "${unitPriceText(record)}",
        quantityText(record),
        changeText(record, row.change),
        ?tooltip,
      ].join(", "),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  record.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LdsColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  record.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _muted,
                ),
              ),
              const SizedBox(width: 8),
              // 단가는 보통 굵기(9.2 예외, 7.12).
              Text(
                unitPriceText(record),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: LdsColors.title,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${dateText(record)} · ${quantityText(record)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _muted,
                ),
              ),
              const SizedBox(width: 8),
              PriceChangeText(record, row.change),
            ],
          ),
        ],
      ),
    );
  }
}
