import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/work_queue_repository_impl.dart";
import "../domain/request_item.dart";
import "../domain/work_queue_state.dart";
import "../../review_progress/domain/review_phase.dart";
import "../../review_progress/presentation/review_progress_view_model.dart";

part "work_queue_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

// Keep network data separate so a progress update does not fetch the list again.
@Riverpod(keepAlive: true, retry: _noRetry)
Future<List<RequestItem>> workQueueRequests(Ref ref) =>
    ref.watch(workQueueRepositoryProvider).getRequests();

@Riverpod(keepAlive: true, retry: _noRetry)
class WorkQueueViewModel extends _$WorkQueueViewModel {
  String _selectedStatus = "전체";
  String _query = "";

  @override
  FutureOr<WorkQueueState> build() {
    // Watch the Future once: watching both it and AsyncValue can invalidate
    // a pending build before an unlistened read receives its result.
    final pending = ref.watch(workQueueRequestsProvider.future);
    final response = ref.read(workQueueRequestsProvider);
    final requests = response.isLoading ? null : response.asData?.value;
    if (requests == null) return pending.then(_composeState);
    return _composeState(requests);
  }

  WorkQueueState _composeState(List<RequestItem> requests) {
    final progress = {
      for (final request in requests)
        request.id: ref
            .watch(reviewProgressViewModelProvider(request.id))
            .when(
              skipLoadingOnRefresh: false,
              data: (phase) => phase,
              loading: () => ReviewPhase.running,
              error: (_, _) => ReviewPhase.failed,
            ),
    };
    return WorkQueueState.fromRequests(
      requests: requests,
      progress: progress,
      selectedStatus: _selectedStatus,
      query: _query,
    );
  }

  void refresh() => ref.invalidate(workQueueRequestsProvider);

  void selectStatus(String status) {
    _selectedStatus = status;
    _updateFilters();
  }

  void search(String query) {
    _query = query;
    _updateFilters();
  }

  void _updateFilters() {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      WorkQueueState(
        requests: current.requests,
        selectedStatus: _selectedStatus,
        query: _query,
      ),
    );
  }
}
