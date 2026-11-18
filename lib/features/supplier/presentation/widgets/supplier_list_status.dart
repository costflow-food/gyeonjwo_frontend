import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/supplier_list_state.dart";

/// 목록 머리: '총 N곳'(검색 중이면 검색어와 결과 수) + 오른쪽 정렬 선택.
class SupplierListStatus extends StatelessWidget {
  const SupplierListStatus({
    super.key,
    required this.data,
    required this.onRetry,
    required this.onSort,
  });

  final SupplierListState data;
  final VoidCallback onRetry;
  final ValueChanged<SupplierSort> onSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: data.query.isEmpty ? "총 " : "'${data.query}' 검색 결과 ",
                ),
                TextSpan(
                  text: "${data.total}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: LdsColors.ink,
                  ),
                ),
                const TextSpan(text: "곳"),
              ],
            ),
            style: const TextStyle(fontSize: 13, color: LdsColors.muted),
          ),
        ),
        if (data.isSearching)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (data.loadFailed)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.error_outline,
              size: 15,
              color: LdsColors.error,
            ),
            label: const Text("조회 실패 · 다시 시도", style: TextStyle(fontSize: 13)),
          ),
        SupplierSortSelect(value: data.sort, onChanged: onSort),
      ],
    );
  }
}

/// 정렬 선택: 높이 32, 1px `#D1D6DC`, 모서리 4, 13px `#333D4B`, 오른쪽 화살표.
/// 아직 고를 수 없는 정렬(예: 최근 거래순)은 흐리게 두고 누를 수 없습니다.
class SupplierSortSelect extends StatelessWidget {
  const SupplierSortSelect({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SupplierSort value;
  final ValueChanged<SupplierSort> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: "정렬",
    child: Container(
      height: 32,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LdsColors.borderStrong),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SupplierSort>(
          value: value,
          isDense: true,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: LdsColors.title,
          ),
          style: const TextStyle(fontSize: 13, color: LdsColors.title),
          onChanged: (sort) {
            if (sort != null) onChanged(sort);
          },
          items: [
            for (final sort in SupplierSort.values)
              DropdownMenuItem(
                value: sort,
                enabled: sort.available,
                child: Text(
                  sort.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: sort.available
                        ? LdsColors.title
                        : LdsColors.disabled,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
