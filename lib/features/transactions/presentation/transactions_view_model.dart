import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/lds/lds.dart";
import "../data/transaction_sample_repository.dart";
import "../domain/purchase_record.dart";
import "../domain/transaction_listing.dart";

/// 오늘 날짜(테스트에서 바꿉니다).
final transactionsTodayProvider = Provider<DateTime>(
  (ref) => ldsDateOnly(DateTime.now()),
);

/// Transactions 위쪽 기간(`docs/design-ssot.md` 7.12). 기본 최근 3개월
/// (오늘−3개월+1일 ~ 오늘). Dashboard 기간과 따로 둡니다.
final transactionsPeriodProvider =
    NotifierProvider<TransactionsPeriod, DateTimeRange>(TransactionsPeriod.new);

class TransactionsPeriod extends Notifier<DateTimeRange> {
  static DateTimeRange recentThreeMonths(DateTime today) {
    final t = ldsDateOnly(today);
    return DateTimeRange(
      start: DateTime(t.year, t.month - 3, t.day + 1),
      end: t,
    );
  }

  @override
  DateTimeRange build() =>
      recentThreeMonths(ref.watch(transactionsTodayProvider));

  void select(DateTimeRange range) => state = range;
}

final transactionRecordsProvider =
    FutureProvider.autoDispose<List<PurchaseRecord>>(
      (ref) => ref.watch(transactionRepositoryProvider).getPurchases(),
    );

/// 필터·정렬·선택. 화면을 떠나면 처음으로 돌아갑니다.
final transactionsViewModelProvider =
    NotifierProvider.autoDispose<TransactionsViewModel, TransactionsFilter>(
      TransactionsViewModel.new,
    );

class TransactionsViewModel extends Notifier<TransactionsFilter> {
  @override
  TransactionsFilter build() => const TransactionsFilter();

  /// 필터를 바꾸면 선택과 'Suppliers에서 넘어왔어요' 안내가 풀립니다.
  void setItems(Set<String> items) => state = state.copyWith(
    items: items,
    selectedId: () => null,
    fromSuppliers: false,
  );

  void setSuppliers(Set<String> suppliers) => state = state.copyWith(
    suppliers: suppliers,
    selectedId: () => null,
    fromSuppliers: false,
  );

  void clearFilters() => state = state.copyWith(
    items: const {},
    suppliers: const {},
    selectedId: () => null,
    fromSuppliers: false,
  );

  /// 목록 위 정렬 선택('최신순 ▾'). 같은 값은 날짜 최신순(목록 규칙).
  void setSort(TransactionSort sort, {required bool descending}) =>
      state = state.copyWith(sort: sort, descending: descending);

  void select(String id) => state = state.copyWith(selectedId: () => id);

  void clearSelection() => state = state.copyWith(selectedId: () => null);

  /// Suppliers에서 넘어온 조건: 그 거래처·품목으로 거르고 그 거래를 고릅니다.
  void applyEntry(List<PurchaseRecord> records, TransactionsEntry entry) {
    final record = findEntryRecord(records, entry);
    if (record == null) return;
    state = state.copyWith(
      items: {record.itemName},
      suppliers: {record.supplierName},
      selectedId: () => entry.date == null ? null : record.id,
      fromSuppliers: true,
    );
  }
}
