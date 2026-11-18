import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../app/app_paths.dart";
import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/purchase_record.dart";
import "../domain/transaction_listing.dart";
import "transactions_view_model.dart";
import "widgets/transaction_detail_panel.dart";
import "widgets/transaction_filter_bar.dart";
import "widgets/transaction_table.dart";

/// Transactions (`/transactions`, `docs/design-ssot.md` 7.12): 확정된 거래를
/// 기간·품목·거래처로 찾아보고, 줄을 고르면 오른쪽 상세 창(380)을 엽니다.
///
/// [entry]는 Suppliers 품목 카드 '마지막 실거래'에서 넘어온 조건입니다.
class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key, this.entry = const TransactionsEntry()});

  final TransactionsEntry entry;

  /// 이 폭 이하에서는 상세 창이 목록 아래로 갑니다.
  static const stackedWidth = 1100.0;

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  /// 넘어온 조건을 이미 적용했는지(한 번만).
  TransactionsEntry? _applied;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(transactionsPeriodProvider);
    final records = ref.watch(transactionRecordsProvider);
    final entry = widget.entry;
    if (!entry.isEmpty && _applied != entry) {
      if (records.value case final loaded?) {
        _applied = entry;
        // 첫 그림 뒤에 상태를 바꿉니다(빌드 중 변경 금지).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(transactionsViewModelProvider.notifier)
                .applyEntry(loaded, entry);
          }
        });
      }
    }
    final dateButton = LdsDateRangeButton(
      value: period,
      today: ref.watch(transactionsTodayProvider),
      onChanged: (range) {
        ref.read(transactionsPeriodProvider.notifier).select(range);
        ref.read(transactionsViewModelProvider.notifier).clearSelection();
      },
    );
    final compact = isCompactLayout(context);
    return WorkspaceShell(
      topAction: compact ? null : dateButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            Align(alignment: Alignment.centerLeft, child: dateButton),
            const SizedBox(height: 16),
          ],
          const Text(
            "Thoner에서 확정됐거나 증빙이 등록된 거래를 기간·품목·거래처로 찾아봅니다.",
            style: TextStyle(fontSize: 15, height: 1.6, color: LdsColors.label),
          ),
          const SizedBox(height: 16),
          AsyncContent<List<PurchaseRecord>>(
            value: records,
            onRetry: () => ref.invalidate(transactionRecordsProvider),
            builder: (loaded) => _Content(records: loaded, period: period),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.records, required this.period});

  final List<PurchaseRecord> records;
  final DateTimeRange period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionsViewModelProvider);
    final viewModel = ref.read(transactionsViewModelProvider.notifier);
    final listing = TransactionListing.build(
      records,
      filter,
      from: period.start,
      to: period.end,
    );
    final table = TransactionTable(
      listing: listing,
      filter: filter,
      onSort: viewModel.sortBy,
      onSelect: viewModel.select,
    );
    final selected = listing.selected;
    final detail = selected == null
        ? null
        : TransactionDetailPanel(
            key: ValueKey(selected.record.id),
            row: selected,
            flow: listing.flow,
            onClose: viewModel.clearSelection,
            onOpenSupplier: () => context.go(AppPaths.suppliers),
          );
    final stacked =
        MediaQuery.sizeOf(context).width <= TransactionsView.stackedWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransactionFilterBar(
          listing: listing,
          filter: filter,
          onItems: viewModel.setItems,
          onSuppliers: viewModel.setSuppliers,
          onClearAll: viewModel.clearFilters,
        ),
        if (filter.fromSuppliers) ...[
          const SizedBox(height: 16),
          _FromSuppliersNote(filter: filter),
        ],
        const SizedBox(height: 16),
        if (detail == null)
          table
        else if (stacked) ...[
          table,
          const SizedBox(height: 16),
          detail,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: table),
              const SizedBox(width: 16),
              SizedBox(width: TransactionDetailPanel.width, child: detail),
            ],
          ),
      ],
    );
  }
}

/// Suppliers에서 넘어왔을 때 안내 띠: `#FFEFE5` 바탕, `#C24A00` 14px.
class _FromSuppliersNote extends StatelessWidget {
  const _FromSuppliersNote({required this.filter});

  final TransactionsFilter filter;

  static const _text = Color(0xFFC24A00);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: LdsColors.primarySoft,
      borderRadius: BorderRadius.circular(LdsRadius.table),
    ),
    child: Text(
      "Suppliers에서 넘어왔어요 · ${filter.suppliers.join(", ")} · "
      "${filter.items.join(", ")}로 걸러 보는 중",
      style: const TextStyle(fontSize: 14, color: _text),
    ),
  );
}
