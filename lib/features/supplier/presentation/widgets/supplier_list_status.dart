import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier_list_state.dart";

/// Result count plus search progress or a retry after a failed search.
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
          child: Text(
            data.query.isEmpty
                ? "총 ${data.total}곳 · 이름순"
                : "'${data.query}' 검색 결과 ${data.total}곳 · 이름순",
            style: const TextStyle(
              fontSize: AppFontSizes.secondary,
              color: muted,
            ),
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
            icon: const Icon(Icons.error_outline, size: 15, color: accent),
            label: const Text(
              "조회 실패 · 다시 시도",
              style: TextStyle(fontSize: AppFontSizes.secondary),
            ),
          ),
      ],
    );
  }
}
