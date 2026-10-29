import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/supplier_repository_impl.dart";
import "../domain/supplier.dart";
import "../domain/supplier_list_state.dart";

part "supplier_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-011 list, search, selection, and registration.
@Riverpod(keepAlive: true, retry: _noRetry)
class SupplierListViewModel extends _$SupplierListViewModel {
  static const searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  // A late response from an older search must not replace a newer one.
  int _requestSerial = 0;

  @override
  Future<SupplierListState> build() async {
    ref.onDispose(() => _searchTimer?.cancel());
    final page = await ref.watch(supplierRepositoryProvider).getSuppliers();
    return SupplierListState(
      query: "",
      suppliers: page.items,
      total: page.total,
      nextCursor: page.nextCursor,
      selectedId: page.items.firstOrNull?.id,
    );
  }

  /// Searches on the server once typing pauses; the cursor starts over.
  void search(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () => _reload(query.trim()));
  }

  void select(String supplierId) {
    final current = state.asData?.value;
    if (current == null || current.selectedId == supplierId) return;
    state = AsyncData(current.copyWith(selectedId: () => supplierId));
  }

  /// Reloads the list and open details with the same query.
  Future<void> refresh() async {
    ref.invalidate(supplierDetailViewModelProvider);
    ref.invalidate(supplierPriceHistoryViewModelProvider);
    final current = state.asData?.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    _searchTimer?.cancel();
    await _reload(current.query);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isSearching) {
      return;
    }
    final serial = _requestSerial;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadFailed: false),
    );
    try {
      final page = await ref
          .read(supplierRepositoryProvider)
          .getSuppliers(query: current.query, cursor: current.nextCursor);
      final latest = state.asData?.value;
      if (!ref.mounted || serial != _requestSerial || latest == null) return;
      state = AsyncData(
        latest.copyWith(
          suppliers: List.unmodifiable([...latest.suppliers, ...page.items]),
          total: page.total,
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      final latest = state.asData?.value;
      if (!ref.mounted || serial != _requestSerial || latest == null) return;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadFailed: true),
      );
    }
  }

  /// Clears the search and selects the new supplier. Returns the created
  /// supplier even if reloading the list fails.
  Future<SupplierDetail> register(
    SupplierDraft draft, {
    required String idempotencyKey,
  }) async {
    final created = await ref
        .read(supplierRepositoryProvider)
        .registerSupplier(draft, idempotencyKey: idempotencyKey);
    if (!ref.mounted) return created;
    _searchTimer?.cancel();
    if (state.asData == null) {
      // The first page never arrived; load from scratch.
      ref.invalidateSelf();
      return created;
    }
    await _reload("", selectId: created.id);
    return created;
  }

  Future<void> _reload(String query, {String? selectId}) async {
    final current = state.asData?.value;
    if (current == null) return;
    final serial = ++_requestSerial;
    state = AsyncData(
      current.copyWith(
        query: query,
        isSearching: true,
        isLoadingMore: false,
        loadFailed: false,
      ),
    );
    try {
      final page = await ref
          .read(supplierRepositoryProvider)
          .getSuppliers(query: query);
      if (!ref.mounted || serial != _requestSerial) return;
      state = AsyncData(
        SupplierListState(
          query: query,
          suppliers: page.items,
          total: page.total,
          nextCursor: page.nextCursor,
          selectedId:
              selectId ??
              SupplierListState.keepSelection(page.items, current.selectedId),
        ),
      );
    } catch (_) {
      if (!ref.mounted || serial != _requestSerial) return;
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSearching: false,
          loadFailed: true,
          selectedId: selectId == null ? null : () => selectId,
        ),
      );
    }
  }
}

/// API-30 detail, kept per supplier.
@Riverpod(keepAlive: true, retry: _noRetry)
class SupplierDetailViewModel extends _$SupplierDetailViewModel {
  @override
  Future<SupplierDetail> build(String supplierId) =>
      ref.watch(supplierRepositoryProvider).getSupplier(supplierId);

  void refresh() => ref.invalidateSelf();
}

/// API-31 price history per supplier item, shown in SCR-005.
@Riverpod(keepAlive: true, retry: _noRetry)
class SupplierPriceHistoryViewModel extends _$SupplierPriceHistoryViewModel {
  @override
  Future<PriceHistory> build(String supplierItemId) =>
      ref.watch(supplierRepositoryProvider).getPriceHistory(supplierItemId);

  void refresh() => ref.invalidateSelf();
}
