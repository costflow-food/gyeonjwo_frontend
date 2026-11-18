import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/supplier_list_state.dart";
import "supplier_list_row.dart";

/// 거래처 카드 목록(카드 사이 8)과 '더 보기'.
class SupplierListPanel extends StatelessWidget {
  const SupplierListPanel({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onLoadMore,
    this.showSelection = true,
  });

  /// False on a phone, where the detail opens on its own screen.
  final bool showSelection;

  final SupplierListState data;
  final ValueChanged<String> onSelect;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (data.suppliers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            data.query.isEmpty
                ? "등록된 거래처 기준자료가 없습니다."
                : "검색 조건과 일치하는 거래처가 없습니다.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, supplier) in data.suppliers.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          SupplierListRow(
            supplier: supplier,
            selected: showSelection && supplier.id == data.selectedId,
            onTap: () => onSelect(supplier.id),
          ),
        ],
        if (data.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: data.isLoadingMore
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: onLoadMore,
                      child: const Text("더 보기"),
                    ),
            ),
          ),
      ],
    );
  }
}
