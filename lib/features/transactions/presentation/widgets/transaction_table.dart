import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/transaction_listing.dart";
import "../transaction_format.dart";
import "price_change_text.dart";

/// 확정 거래 표 (`docs/design-ssot.md` 7.12, 9.2): 머리 '확정 거래 N건 · 총 N원'
/// + 확정일 · 품목 · 거래처 · 수량 · 단가 · 총액. 좁으면 가로로 스크롤.
class TransactionTable extends StatelessWidget {
  const TransactionTable({
    super.key,
    required this.listing,
    required this.filter,
    required this.onSort,
    required this.onSelect,
  });

  final TransactionListing listing;
  final TransactionsFilter filter;
  final ValueChanged<TransactionSort> onSort;
  final ValueChanged<String> onSelect;

  /// 이보다 좁으면 가로 스크롤.
  static const minWidth = 760.0;

  static const _empty = "이 기간·조건에 확정된 거래가 없어요. 기간을 넓히거나 필터를 지워 보세요.";

  LdsColumn _sortable(String label, TransactionSort sort, {int flex = 1}) =>
      LdsColumn(
        label,
        flex: flex,
        sort: filter.sort != sort
            ? LdsSortState.none
            : filter.descending
            ? LdsSortState.descending
            : LdsSortState.ascending,
        onSort: () => onSort(sort),
      );

  @override
  Widget build(BuildContext context) {
    final currency = listing.rows.firstOrNull?.record.currency ?? "KRW";
    return Semantics(
      container: true,
      label: "확정 거래 목록",
      child: LdsListTable(
        minWidth: minWidth,
        header: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Semantics(
            liveRegion: true,
            child: Text(
              "확정 거래 ${listing.rows.length}건 · 총 "
              "${formatAmount(listing.totalAmount)}${currencyText(currency)}",
              style: const TextStyle(fontSize: 14, color: LdsColors.label),
            ),
          ),
        ),
        empty: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Text(
            _empty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: LdsColors.muted),
          ),
        ),
        columns: [
          _sortable("확정일", TransactionSort.date),
          const LdsColumn("품목", flex: 2, alignStart: true),
          const LdsColumn("거래처", alignStart: true),
          _sortable("수량", TransactionSort.quantity),
          _sortable("단가", TransactionSort.unitPrice, flex: 2),
          _sortable("총액", TransactionSort.total, flex: 2),
        ],
        rows: [
          for (final row in listing.rows)
            LdsListRow(
              [
                Text(dateText(row.record)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.record.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: LdsColors.ink,
                      ),
                    ),
                    if (row.record.specification case final spec?)
                      Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: LdsColors.muted,
                        ),
                      ),
                  ],
                ),
                Text(row.record.supplierName),
                LdsNumberUnit(
                  formatAmount(row.record.quantity),
                  row.record.unit,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 단가는 보통 굵기(9.2 예외, 7.12).
                    Text(
                      unitPriceText(row.record),
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: LdsColors.title,
                      ),
                    ),
                    PriceChangeText(row.record, row.change),
                  ],
                ),
                LdsNumberUnit(
                  formatAmount(row.record.totalAmount),
                  currencyText(row.record.currency),
                ),
              ],
              selected: row.record.id == filter.selectedId,
              onTap: () => onSelect(row.record.id),
              semanticLabel:
                  "${dateText(row.record)} ${row.record.itemName} "
                  "${row.record.supplierName} ${unitPriceText(row.record)}",
            ),
        ],
      ),
    );
  }
}
