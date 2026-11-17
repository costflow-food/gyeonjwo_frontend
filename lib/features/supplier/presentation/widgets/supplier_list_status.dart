import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/supplier_list_state.dart";

class SupplierListStatus extends StatelessWidget {
  const SupplierListStatus({
    super.key,
    required this.data,
    required this.onRetry,
  });

  final SupplierListState data;
  final VoidCallback onRetry;

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
                const TextSpan(text: "곳 · 이름순"),
              ],
            ),
            style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        ),
        if (data.isSearching)
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
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
      ],
    );
  }
}
