import "request_item.dart";
import "../../review_progress/domain/review_phase.dart";

class WorkQueueState {
  WorkQueueState({
    required List<RequestItem> requests,
    this.selectedStatus = "전체",
    this.query = "",
  }) : requests = List.unmodifiable(requests);

  factory WorkQueueState.fromRequests({
    required List<RequestItem> requests,
    required Map<String, ReviewPhase> progress,
    String selectedStatus = "전체",
    String query = "",
  }) => WorkQueueState(
    requests: [
      for (final request in requests)
        switch (progress[request.id] ?? ReviewPhase.idle) {
          ReviewPhase.idle => request,
          ReviewPhase.running => request.copyWith(
            status: "검토 중",
            action: "진행 보기",
          ),
          ReviewPhase.completed => request.copyWith(
            status: "완료",
            action: "결과 보기",
          ),
          ReviewPhase.failed => request.copyWith(
            status: "검토 필요",
            action: "다시 시도",
          ),
        },
    ],
    selectedStatus: selectedStatus,
    query: query,
  );

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
