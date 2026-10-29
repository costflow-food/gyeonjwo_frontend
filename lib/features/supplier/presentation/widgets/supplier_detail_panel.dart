import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/widgets/outline_panel.dart";
import "../supplier_view_model.dart";
import "supplier_detail_content.dart";
import "supplier_load_error.dart";

/// SCR-011 detail area (API-30), loaded per selected supplier.
class SupplierDetailPanel extends ConsumerWidget {
  const SupplierDetailPanel({super.key, required this.supplierId});
  final String supplierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = supplierDetailViewModelProvider(supplierId);
    return OutlinePanel(
      child: ref
          .watch(provider)
          .when(
            skipLoadingOnRefresh: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SupplierLoadError(
              error: error,
              fallback: "거래처 정보를 불러오지 못했습니다.",
              onRetry: () => ref.read(provider.notifier).refresh(),
            ),
            data: (supplier) => SupplierDetailContent(supplier: supplier),
          ),
    );
  }
}
