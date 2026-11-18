import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
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
          // 좁은 폭에서는 글자를 줄여 정렬 단추와 한 줄에 둡니다.
          Flexible(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.error_outline,
                size: 15,
                color: LdsColors.error,
              ),
              label: const Text(
                "조회 실패 · 다시 시도",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        SupplierSortSelect(value: data.sort, onChanged: onSort),
      ],
    );
  }
}

/// 정렬 선택: Invoices '최신순 ▾'와 같은 [LdsSortButton]. 아직 못 고르는
/// 정렬(최근 거래순)은 회색으로 보입니다.
class SupplierSortSelect extends StatelessWidget {
  const SupplierSortSelect({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SupplierSort value;
  final ValueChanged<SupplierSort> onChanged;

  @override
  Widget build(BuildContext context) => LdsSortButton<SupplierSort>(
    choices: [
      for (final sort in SupplierSort.values)
        LdsSortChoice(sort, sort.label, enabled: sort.available),
    ],
    selected: value,
    onChanged: onChanged,
  );
}
