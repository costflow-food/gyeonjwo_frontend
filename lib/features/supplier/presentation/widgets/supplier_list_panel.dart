import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/supplier.dart";
import "../../domain/supplier_list_state.dart";
import "supplier_list_row.dart";

/// 거래처 목록: 카드(사이 8)를 [SupplierListState.sortedSuppliers] 순서로
/// 쌓고 '더 보기'. 스크롤은 감싸는 쪽이 둡니다.
class SupplierListPanel extends StatelessWidget {
  const SupplierListPanel({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onLoadMore,
    this.showSelection = true,
    this.selectedKey,
  });

  /// False on a phone, where the detail opens on its own screen.
  final bool showSelection;

  final SupplierListState data;
  final ValueChanged<String> onSelect;
  final VoidCallback onLoadMore;

  /// 고른 줄에 붙입니다(↑/↓로 옮긴 뒤 보이게).
  final GlobalKey? selectedKey;

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
        for (final (index, supplier) in data.sortedSuppliers.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          _row(supplier),
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

  Widget _row(SupplierSummary supplier) {
    final selected = showSelection && supplier.id == data.selectedId;
    return SupplierListRow(
      key: selected ? selectedKey : null,
      supplier: supplier,
      selected: selected,
      query: data.query,
      onTap: () => onSelect(supplier.id),
    );
  }
}
