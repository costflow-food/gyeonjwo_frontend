import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../supplier_view_model.dart";
import "price_column.dart";
import "supplier_load_error.dart";
import "supplier_section_title.dart";

/// API-31 history. Mail quotes and actual purchases are separate columns.
class PriceHistorySection extends ConsumerWidget {
  const PriceHistorySection({super.key, required this.supplierItemId});
  final String supplierItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = supplierPriceHistoryViewModelProvider(supplierItemId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SupplierSectionTitle("가격 이력", large: true),
        const SizedBox(height: 12),
        ref
            .watch(provider)
            .when(
              skipLoadingOnRefresh: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SupplierLoadError(
                error: error,
                fallback: "가격 이력을 불러오지 못했습니다.",
                onRetry: () => ref.read(provider.notifier).refresh(),
              ),
              data: (history) => LayoutBuilder(
                builder: (context, constraints) {
                  final quotes = PriceColumn(
                    title: "참고 견적",
                    caption: "메일 견적 기준 · 실제 거래가 아님",
                    emptyText: "확인된 참고 견적이 없습니다.",
                    dateSuffix: "적용",
                    records: history.referenceQuotes,
                  );
                  final purchases = PriceColumn(
                    title: "실제 거래",
                    caption: "영수증·거래명세서 등 증빙 기준",
                    emptyText: "확인된 실거래 이력이 없습니다.",
                    dateSuffix: "거래",
                    records: history.actualPurchases,
                  );
                  if (constraints.maxWidth < 620) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        quotes,
                        const SizedBox(height: 16),
                        purchases,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: quotes),
                      const SizedBox(width: 16),
                      Expanded(child: purchases),
                    ],
                  );
                },
              ),
            ),
      ],
    );
  }
}
