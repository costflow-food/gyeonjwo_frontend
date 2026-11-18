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
    this.allCounts,
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

  /// 검색과 무관한 상태 탭 건수(Dashboard 카드용). 검색 중에는 마지막으로
  /// 본 검색 없는 값을 유지합니다. 아직 모르면 null.
  final WorkQueueCounts? allCounts;

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
    allCounts: allCounts,
  );

  WorkQueueState withStatus(TaskGroup? tab) => WorkQueueState(
    items: items,
    counts: counts,
    nextCursor: nextCursor,
    status: tab,
    query: query,
    selectedId: selectedId,
    loadingMore: loadingMore,
    allCounts: allCounts,
  );

  WorkQueueState withMore({
    required List<WorkCase> items,
    required String? nextCursor,
    required bool loadingMore,
    WorkQueueCounts? counts,
    WorkQueueCounts? allCounts,
  }) => WorkQueueState(
    items: items,
    counts: counts ?? this.counts,
    nextCursor: nextCursor,
    status: status,
    query: query,
    selectedId: selectedId,
    loadingMore: loadingMore,
    allCounts: allCounts ?? this.allCounts,
  );
}

/// 품목별 그룹. 품목 이름 가나다순, 품목 미확인은 맨 뒤입니다. 묶음 안은
/// 최신 수신순입니다.
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
  // 한글 음절은 유니코드에서 가나다 차례라 코드값 비교로 충분합니다.
  groups.sort((a, b) {
    if (a.itemName == null) return b.itemName == null ? 0 : 1;
    if (b.itemName == null) return -1;
    return a.itemName!.compareTo(b.itemName!);
  });
  return List.unmodifiable(groups);
}

/// 탭에 보일 업무. 전체 탭은 보관 전 업무와 완료(보관) 업무를 함께 보이고,
/// 완료 탭은 완료 업무만 보입니다. [completed]가 아직 없으면 빼고 셉니다.
List<WorkCase> tabCases(
  TaskGroup? status, {
  required List<WorkCase> active,
  List<WorkCase>? completed,
}) => switch (status) {
  null => [...active, ...?completed],
  TaskGroup.complete => [...?completed],
  _ => [
    for (final workCase in active)
      if (taskGroupOf(workCase) == status) workCase,
  ],
};

/// 목록에 보이는 차례(묶음 순서 → 묶음 안 순서)대로 편 업무. 접힌 묶음
/// ([collapsed]의 품목)은 건너뜁니다.
List<WorkCase> orderedCases(
  List<WorkCaseGroup> groups, {
  Set<String?> collapsed = const {},
}) => [
  for (final group in groups)
    if (!collapsed.contains(group.itemName)) ...group.cases,
];
