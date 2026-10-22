import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/work_queue_repository_impl.dart";
import "../domain/request_item.dart";

final workQueueViewModelProvider =
    AsyncNotifierProvider<WorkQueueViewModel, WorkQueueState>(
      WorkQueueViewModel.new,
      retry: (_, _) => null,
    );

class WorkQueueState {
  WorkQueueState({
    required List<RequestItem> requests,
    this.selectedStatus = "전체",
    this.query = "",
  }) : requests = List.unmodifiable(requests);

  final List<RequestItem> requests;
  final String selectedStatus;
  final String query;

  int countFor(String status) => status == "전체"
      ? requests.length
      : requests.where((request) => request.status == status).length;

  List<RequestItem> get visibleRequests {
    final keyword = query.trim().toLowerCase();
    return requests
        .where((request) {
          final matchesStatus =
              selectedStatus == "전체" || request.status == selectedStatus;
          final matchesQuery =
              request.title.toLowerCase().contains(keyword) ||
              request.supplier.toLowerCase().contains(keyword);
          return matchesStatus && matchesQuery;
        })
        .toList(growable: false);
  }
}

class WorkQueueViewModel extends AsyncNotifier<WorkQueueState> {
  @override
  Future<WorkQueueState> build() async {
    final repository = ref.watch(workQueueRepositoryProvider);
    final requests = await repository.getRequests();
    return WorkQueueState(requests: requests);
  }

  void refresh() => ref.invalidateSelf();

  void selectStatus(String status) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      WorkQueueState(
        requests: current.requests,
        selectedStatus: status,
        query: current.query,
      ),
    );
  }

  void search(String query) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      WorkQueueState(
        requests: current.requests,
        selectedStatus: current.selectedStatus,
        query: query,
      ),
    );
  }
}
