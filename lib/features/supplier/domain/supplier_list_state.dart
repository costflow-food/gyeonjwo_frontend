import "supplier.dart";

/// 목록 정렬. 서버(API-29)는 이름순으로만 주므로 받은 줄 안에서 바꿉니다.
enum SupplierSort {
  name("이름순"),

  /// 목록 API에 최근 거래일이 없어 아직 고를 수 없습니다.
  recentTransaction("최근 거래순", available: false),
  itemCount("품목 많은 순");

  const SupplierSort(this.label, {this.available = true});
  final String label;
  final bool available;
}

/// SCR-011 list state. Search runs on the server (API-29), not in the view.
class SupplierListState {
  const SupplierListState({
    required this.query,
    required this.suppliers,
    required this.total,
    this.nextCursor,
    this.selectedId,
    this.sort = SupplierSort.name,
    this.isSearching = false,
    this.isLoadingMore = false,
    this.loadFailed = false,
  });

  final String query;
  final List<SupplierSummary> suppliers;
  final int total;
  final String? nextCursor;
  final String? selectedId;
  final SupplierSort sort;

  /// Searching or refreshing; the current rows stay visible meanwhile.
  final bool isSearching;
  final bool isLoadingMore;

  /// The last search or page load failed; the current rows stay.
  final bool loadFailed;

  bool get hasMore => nextCursor != null;

  /// [sort] 순서로 놓은 목록(같으면 서버 순서 = 이름순).
  List<SupplierSummary> get sortedSuppliers => switch (sort) {
    SupplierSort.name || SupplierSort.recentTransaction => suppliers,
    SupplierSort.itemCount => [
      for (final (_, supplier)
          in (suppliers.indexed.toList()..sort((a, b) {
            final byCount = b.$2.itemNames.length.compareTo(
              a.$2.itemNames.length,
            );
            return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
          })))
        supplier,
    ],
  };

  SupplierSummary? get selected =>
      suppliers.where((supplier) => supplier.id == selectedId).firstOrNull;

  SupplierListState copyWith({
    String? query,
    List<SupplierSummary>? suppliers,
    int? total,
    String? Function()? nextCursor,
    String? Function()? selectedId,
    SupplierSort? sort,
    bool? isSearching,
    bool? isLoadingMore,
    bool? loadFailed,
  }) {
    return SupplierListState(
      query: query ?? this.query,
      suppliers: suppliers ?? this.suppliers,
      total: total ?? this.total,
      nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
      selectedId: selectedId == null ? this.selectedId : selectedId(),
      sort: sort ?? this.sort,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }

  /// Keeps the selection only if it is still in the new first page.
  static String? keepSelection(
    List<SupplierSummary> suppliers,
    String? preferredId,
  ) {
    if (suppliers.any((supplier) => supplier.id == preferredId)) {
      return preferredId;
    }
    return suppliers.firstOrNull?.id;
  }
}
