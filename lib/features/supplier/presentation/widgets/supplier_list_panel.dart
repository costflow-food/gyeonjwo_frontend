import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier_list_state.dart";
import "supplier_list_row.dart";

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
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: context.palette.muted,
            ),
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
            selected: showSelection && supplier.id == data.selectedId,
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
