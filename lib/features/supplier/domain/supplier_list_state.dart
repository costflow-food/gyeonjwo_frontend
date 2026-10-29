import "supplier.dart";

/// SCR-011 list state. Search runs on the server (API-29), not in the view.
class SupplierListState {
  const SupplierListState({
    required this.query,
    required this.suppliers,
    required this.total,
    this.nextCursor,
    this.selectedId,
    this.isSearching = false,
    this.isLoadingMore = false,
    this.loadFailed = false,
  });

  final String query;
  final List<SupplierSummary> suppliers;
  final int total;
  final String? nextCursor;
  final String? selectedId;

  /// Searching or refreshing; the current rows stay visible meanwhile.
  final bool isSearching;
  final bool isLoadingMore;

  /// The last search or page load failed; the current rows stay.
  final bool loadFailed;

  bool get hasMore => nextCursor != null;

  SupplierSummary? get selected =>
      suppliers.where((supplier) => supplier.id == selectedId).firstOrNull;

  SupplierListState copyWith({
    String? query,
    List<SupplierSummary>? suppliers,
    int? total,
    String? Function()? nextCursor,
    String? Function()? selectedId,
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
