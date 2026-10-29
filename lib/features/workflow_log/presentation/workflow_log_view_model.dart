import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/workflow_log_repository_impl.dart";
import "../domain/workflow_log_filter.dart";
import "../domain/workflow_log_state.dart";

part "workflow_log_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-010 filters, selection, and cursor paging.
@Riverpod(keepAlive: true, retry: _noRetry)
class WorkflowLogViewModel extends _$WorkflowLogViewModel {
  static const searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  // Typed text not applied yet; a dropdown change must not drop it.
  String? _pendingQuery;

  // A late response for an older filter must not replace a newer one.
  int _requestSerial = 0;

  @override
  Future<WorkflowLogState> build() async {
    ref.onDispose(() => _searchTimer?.cancel());
    const filter = WorkflowLogFilter();
    final page = await ref.watch(workflowLogRepositoryProvider).getLogs(filter);
    return WorkflowLogState(
      filter: filter,
      entries: page.items,
      total: page.total,
      nextCursor: page.nextCursor,
      selectedId: page.items.firstOrNull?.id,
    );
  }

  /// Text search waits for typing to pause; other filters apply at once.
  void searchCase(String query) {
    _pendingQuery = query.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final current = state.asData?.value;
      if (current == null) return;
      applyFilter(current.filter);
    });
  }

  void applyFilter(WorkflowLogFilter filter) {
    _searchTimer?.cancel();
    final query = _pendingQuery;
    _pendingQuery = null;
    _reload(query == null ? filter : filter.copyWith(caseQuery: query));
  }

  void resetFilter() {
    _pendingQuery = null;
    applyFilter(const WorkflowLogFilter());
  }

  void select(String id) {
    final current = state.asData?.value;
    if (current == null || current.selectedId == id) return;
    state = AsyncData(current.copyWith(selectedId: () => id));
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    _searchTimer?.cancel();
    await _reload(current.filter);
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
          .read(workflowLogRepositoryProvider)
          .getLogs(current.filter, cursor: current.nextCursor);
      if (!ref.mounted || serial != _requestSerial) return;
      final latest = state.asData?.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          entries: List.unmodifiable([...latest.entries, ...page.items]),
          total: page.total,
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (!ref.mounted || serial != _requestSerial) return;
      final latest = state.asData?.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadFailed: true),
      );
    }
  }

  Future<void> _reload(WorkflowLogFilter filter) async {
    final current = state.asData?.value;
    if (current == null) return;
    final serial = ++_requestSerial;
    state = AsyncData(
      current.copyWith(
        filter: filter,
        isSearching: true,
        isLoadingMore: false,
        loadFailed: false,
      ),
    );
    try {
      final page = await ref
          .read(workflowLogRepositoryProvider)
          .getLogs(filter);
      if (!ref.mounted || serial != _requestSerial) return;
      final keep = page.items.any((entry) => entry.id == current.selectedId);
      state = AsyncData(
        WorkflowLogState(
          filter: filter,
          entries: page.items,
          total: page.total,
          nextCursor: page.nextCursor,
          selectedId: keep ? current.selectedId : page.items.firstOrNull?.id,
        ),
      );
    } catch (_) {
      if (!ref.mounted || serial != _requestSerial) return;
      final latest = state.asData?.value ?? current;
      state = AsyncData(latest.copyWith(isSearching: false, loadFailed: true));
    }
  }
}
