import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../app/app_paths.dart";
import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../../shared/widgets/list_detail_layout.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/purchase_record.dart";
import "../domain/transaction_listing.dart";
import "transaction_format.dart";
import "transactions_view_model.dart";
import "widgets/transaction_detail_panel.dart";
import "widgets/transaction_filter_bar.dart";
import "widgets/transaction_list_row.dart";

import "widgets/transaction_sort_button.dart";

/// Transactions (`/transactions`, `docs/design-ssot.md` 7.12): 확정된 거래를
/// 기간·품목·거래처로 찾아봅니다. Tasks와 같은 목록 칸 + 상세 칸
/// ([ListDetailLayout]): 넓은 화면은 첫 거래를 골라 열고, 1100px 이하는 한
/// 화면씩(목록 → 고르면 상세 → '목록으로').
///
/// [entry]는 Suppliers 품목 카드 '마지막 실거래'에서 넘어온 조건입니다.
class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key, this.entry = const TransactionsEntry()});

  final TransactionsEntry entry;

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
    Widget content() => AsyncContent<List<PurchaseRecord>>(
      value: records,
      onRetry: () => ref.invalidate(transactionRecordsProvider),
      builder: (loaded) => _Content(records: loaded, period: period),
    );
    return WorkspaceShell(
      scrollable: isCompactLayout(context),
      topAction: const LdsDateViewButton(),
      child: content(),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.records, required this.period});

  final List<PurchaseRecord> records;
  final DateTimeRange period;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  final _selectedRow = GlobalKey(debugLabel: "고른 거래 줄");

  /// 넓은 화면에서 고른 거래가 없으면 보이는 첫 거래를 고릅니다(Tasks와
  /// 같게). 필터·기간을 바꿔 선택이 풀려도 다시 첫 거래를 고릅니다.
  /// Suppliers에서 넘어온 조건은 첫 그림 뒤에 적용되므로, 그 조건이 고른
  /// 거래를 덮어쓰지 않게 한 번 더 미룹니다.
  void _autoSelect(TransactionListing listing) {
    if (listing.rows.isEmpty || listing.selected != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filter = ref.read(transactionsViewModelProvider);
      final now = TransactionListing.build(
        widget.records,
        filter,
        from: widget.period.start,
        to: widget.period.end,
      );
      final first = now.rows.firstOrNull;
      if (now.selected != null || first == null) return;
      ref.read(transactionsViewModelProvider.notifier).select(first.record.id);
    });
  }

  void _step(TransactionListing listing, int step) {
    final rows = listing.rows;
    final selectedId = listing.selected?.record.id;
    final at = rows.indexWhere((row) => row.record.id == selectedId);
    final next = at == -1 ? 0 : at + step;
    if (next < 0 || next >= rows.length) return;
    ref
        .read(transactionsViewModelProvider.notifier)
        .select(rows[next].record.id);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionsViewModelProvider);
    final viewModel = ref.read(transactionsViewModelProvider.notifier);
    final listing = TransactionListing.build(
      widget.records,
      filter,
      from: widget.period.start,
      to: widget.period.end,
    );
    final selected = listing.selected;
    final selectedId = selected?.record.id;
    final dateButton = LdsDateRangeButton(
      value: widget.period,
      invoice: true,
      today: ref.watch(transactionsTodayProvider),
      onChanged: (range) {
        ref.read(transactionsPeriodProvider.notifier).select(range);
        viewModel.clearSelection();
      },
    );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filter.fromSuppliers) ...[
          _FromSuppliersNote(filter: filter),
          const SizedBox(height: 12),
        ],
        TransactionFilterBar(
          listing: listing,
          filter: filter,
          onItems: viewModel.setItems,
          onSuppliers: viewModel.setSuppliers,
          onMethods: viewModel.setMethods,
          onClearAll: viewModel.clearFilters,
          trailing: dateButton,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Summary(listing: listing),
            TransactionSortButton(filter: filter, onChanged: viewModel.setSort),
          ],
        ),
      ],
    );
    final rows = listing.rows.isEmpty
        ? const _Empty()
        : ListArrowKeys(
            onStep: (step) => _step(listing, step),
            selectedKey: _selectedRow,
            child: Semantics(
              container: true,
              label: "확정 거래 목록",
              child: ListGroupBox(
                children: [
                  for (final row in listing.rows)
                    TransactionListRow(
                      key: row.record.id == selectedId ? _selectedRow : null,
                      row: row,
                      selected: row.record.id == selectedId,
                      onTap: () => viewModel.select(row.record.id),
                    ),
                ],
              ),
            ),
          );
    Widget detail() => selected == null
        ? const SizedBox.shrink()
        : TransactionDetailPanel(
            key: ValueKey(selected.record.id),
            row: selected,
            flow: listing.flow,
            onOpenSupplier: () => context.go(AppPaths.suppliers),
          );
    if (isCompactLayout(context)) {
      // 휴대폰: 목록, 또는 '목록으로'가 있는 고른 거래.
      if (selected != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: viewModel.clearSelection,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("목록으로"),
            ),
            const SizedBox(height: 8),
            detail(),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, const SizedBox(height: 12), rows],
      );
    }
    if (!ListDetailLayout.isSinglePane(context)) _autoSelect(listing);
    return ListDetailLayout(
      detailPadding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      detailAlone: selected != null,
      onBack: viewModel.clearSelection,
      list: (padding, wide) =>
          ListPaneColumn(padding: padding, header: header, body: rows),
      detail: (_) => detail(),
    );
  }
}

/// 목록 위 '확정 거래 N건 · 총 N원'.
class _Summary extends StatelessWidget {
  const _Summary({required this.listing});

  final TransactionListing listing;

  @override
  Widget build(BuildContext context) {
    final currency = listing.rows.firstOrNull?.record.currency ?? "KRW";
    return Semantics(
      liveRegion: true,
      child: Text(
        "확정 거래 ${listing.rows.length}건 · 총 "
        "${formatAmount(listing.totalAmount)}${currencyText(currency)}",
        style: const TextStyle(fontSize: 13, color: LdsColors.label),
      ),
    );
  }
}

/// 결과가 없을 때 목록 칸 문구. 상세 칸은 비웁니다.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
    child: Text(
      "이 기간·조건에 확정된 거래가 없어요. 기간을 넓히거나 필터를 지워 보세요.",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 15, color: LdsColors.muted),
    ),
  );
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
