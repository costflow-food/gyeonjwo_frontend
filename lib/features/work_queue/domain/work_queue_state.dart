import "task_group.dart";
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
    this.allConfirm,
  });

  /// 검색어에 맞는 보관 전 업무 전체(모든 탭). 탭은 이 목록을 화면에서
  /// 거릅니다. 완료(보관)는 `completedTasksProvider`가 따로 읽습니다.
  final List<WorkCase> items;
  final WorkQueueCounts counts;

  /// Set while cases are still on the server: the pages after the first
  /// are on their way ([loadingMore] is true), a page failed, or the list
  /// is past the page limit of one load.
  final String? nextCursor;

  /// null은 전체 탭입니다.
  final TaskGroup? status;
  final String query;
  final String? selectedId;
  final bool loadingMore;

  /// 검색과 무관한 확인 필요 건수(첫 화면 요약용). 검색 중에는 마지막으로
  /// 본 검색 없는 값을 유지합니다. 아직 모르면 null.
  final int? allConfirm;

  List<WorkCase> get visibleItems => status == null
      ? items
      : [
          for (final workCase in items)
            if (taskGroupOf(workCase) == status) workCase,
        ];

  /// 지금 탭의 품목별 그룹([groupCases]).
  List<WorkCaseGroup> get groups => groupCases(visibleItems);

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
    allConfirm: allConfirm,
  );

  WorkQueueState withStatus(TaskGroup? tab) => WorkQueueState(
    items: items,
    counts: counts,
    nextCursor: nextCursor,
    status: tab,
    query: query,
    selectedId: selectedId,
    loadingMore: loadingMore,
    allConfirm: allConfirm,
  );

  WorkQueueState withMore({
    required List<WorkCase> items,
    required String? nextCursor,
    required bool loadingMore,
    WorkQueueCounts? counts,
    int? allConfirm,
  }) => WorkQueueState(
    items: items,
    counts: counts ?? this.counts,
    nextCursor: nextCursor,
    status: status,
    query: query,
    selectedId: selectedId,
    loadingMore: loadingMore,
    allConfirm: allConfirm ?? this.allConfirm,
  );
}

/// 품목별 그룹. 가장 최근 메일이 온 품목이 먼저, 품목 미확인은 맨 뒤입니다.
List<WorkCaseGroup> groupCases(Iterable<WorkCase> cases) {
  final byItem = <String?, List<WorkCase>>{};
  for (final workCase in cases) {
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
