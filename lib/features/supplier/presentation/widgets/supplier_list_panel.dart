import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier_list_state.dart";
import "supplier_list_row.dart";

/// Rows, empty states, and cursor-based "더 보기".
class SupplierListPanel extends StatelessWidget {
  const SupplierListPanel({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onLoadMore,
  });

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
            style: const TextStyle(fontSize: AppFontSizes.body, color: muted),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final supplier in data.suppliers)
          SupplierListRow(
            supplier: supplier,
            selected: supplier.id == data.selectedId,
            onTap: () => onSelect(supplier.id),
          ),
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
                      child: const Text(
                        "더 보기",
                        style: TextStyle(fontSize: AppFontSizes.button),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
