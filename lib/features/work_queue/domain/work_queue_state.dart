import "work_case.dart";

class WorkQueueState {
  const WorkQueueState({
    required this.items,
    required this.counts,
    this.nextCursor,
    this.status,
    this.query = "",
    this.selectedId,
    this.loadingMore = false,
  });

  final List<WorkCase> items;
  final WorkQueueCounts counts;
  final String? nextCursor;

  /// null은 전체 탭입니다.
  final WorkCaseStatus? status;
  final String query;
  final String? selectedId;
  final bool loadingMore;

  /// 품목별 그룹. 가장 최근 메일이 온 품목이 먼저, 품목 미확인은 맨 뒤입니다.
  List<WorkCaseGroup> get groups {
    final byItem = <String?, List<WorkCase>>{};
    for (final workCase in items) {
      final name = workCase.itemName?.trim();
      byItem
          .putIfAbsent(name == null || name.isEmpty ? null : name, () => [])
          .add(workCase);
    }
    final groups = [
      for (final entry in byItem.entries)
        WorkCaseGroup(
          itemName: entry.key,
          cases: List.unmodifiable(
            entry.value..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
          ),
        ),
    ];
    groups.sort((a, b) {
      if (a.itemName == null) return 1;
      if (b.itemName == null) return -1;
      return b.cases.first.receivedAt.compareTo(a.cases.first.receivedAt);
    });
    return List.unmodifiable(groups);
  }

  WorkCase? get selected =>
      items.where((workCase) => workCase.id == selectedId).firstOrNull;

  WorkQueueState select(String? id) => WorkQueueState(
    items: items,
    counts: counts,
    nextCursor: nextCursor,
    status: status,
    query: query,
    selectedId: id,
    loadingMore: loadingMore,
  );

  WorkQueueState withMore({
    required List<WorkCase> items,
    required String? nextCursor,
    required bool loadingMore,
  }) => WorkQueueState(
    items: items,
    counts: counts,
    nextCursor: nextCursor,
    status: status,
    query: query,
    selectedId: selectedId,
    loadingMore: loadingMore,
  );
}
