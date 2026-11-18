import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/app_icons.dart";
import "../../../../shared/widgets/list_detail_layout.dart";
import "../../domain/transaction_listing.dart";
import "../transaction_format.dart";

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
  @override
  Widget build(BuildContext context) {
    final r = row.record, c = row.change;
    final delta = c.isFirst
        ? '첫 거래'
        : c.difference == 0
        ? '같음'
        : '${c.difference > 0 ? '▲' : '▼'}${formatPercent(c.percent)}%';
    return Tooltip(
      message:
          '${r.supplierName} · ${dateText(r)} · ${changeTooltip(c) ?? '첫 거래'}',
      child: ListSelectableRow(
        selected: selected,
        onTap: onTap,
        semanticLabel:
            '${r.itemName}, ${r.supplierName}, ${dateText(r)}, ${unitPriceText(r)}, $delta',
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: 128,
                child: Row(
                  children: [
                    const AppIconView(
                      AppIcon.transactions,
                      size: 16,
                      color: LdsColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  r.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: LdsColors.label),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 64,
                child: Text(
                  '${formatAmount(r.unitPrice)}${currencyText(r.currency)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 44,
                child: Text(
                  delta,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.difference > 0
                        ? LdsColors.priceUp
                        : c.difference < 0
                        ? LdsColors.priceDown
                        : LdsColors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
