import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/task_group.dart";
import "../../domain/work_case.dart";
import "../../domain/work_queue_state.dart";
import "../completed_tasks_view_model.dart";
import "../task_search_request.dart";
import "../work_queue_view_model.dart";
import "task_row.dart";

/// 목록이 다시 만들어져도(업무를 열면 화면이 바뀝니다) 남길 것.
class TaskListMemory {
  /// 탭별 스크롤 위치. null 키는 전체 탭입니다.
  final scrollOffsets = <TaskGroup?, double>{};

  /// 펼친 품목 묶음. null은 '품목 미확인'입니다. 묶음은 접힌 채로 시작하고,
  /// 여기 든 것만 펼쳐 보입니다(새로고침하면 다시 모두 접힙니다).
  final expanded = <String?>{};

  /// 묶음을 펼쳐서 보여 준 고른 업무. 같은 업무로는 다시 펼치지 않아, 그
  /// 묶음을 사용자가 접을 수 있습니다.
  String? revealedId;

  /// [groups] 가운데 접혀 있는 묶음.
  Set<String?> collapsedIn(List<WorkCaseGroup> groups) => {
    for (final group in groups)
      if (!expanded.contains(group.itemName)) group.itemName,
  };

  /// ↑/↓로 다른 업무를 열었습니다. 업무를 열면 목록이 새로 만들어지므로 새
  /// 목록이 초점을 이어받습니다.
  bool keyboardMoved = false;
}

final taskListMemoryProvider = Provider<TaskListMemory>(
  (ref) => TaskListMemory(),
);

/// [status] 탭 목록에 지금 보이는 품목 묶음(받아 둔 업무 기준).
List<WorkCaseGroup> taskListGroups(WidgetRef ref, TaskGroup? status) {
  final data = ref.read(workQueueViewModelProvider).value;
  if (data == null) return const [];
  final completed = ref.read(completedTasksViewModelProvider(data.query)).value;
  return groupCases(
    tabCases(status, active: data.items, completed: completed?.items),
  );
}

/// [status] 탭 목록에 보이는 차례대로 편 업무(접힌 묶음 제외).
List<WorkCase> taskListOrder(WidgetRef ref, TaskGroup? status) {
  final groups = taskListGroups(ref, status);
  return orderedCases(
    groups,
    collapsed: ref.read(taskListMemoryProvider).collapsedIn(groups),
  );
}

/// Tasks 목록 (`docs/design-ssot.md` 7.13, 7.14): 검색칸 · 상태 탭 4개 ·
/// 품목 묶음 상자. 탭은 주소(`?tab=`)가 기준이라 [onTab]으로 주소를 바꿉니다.
class TaskList extends ConsumerStatefulWidget {
  const TaskList({
    super.key,
    required this.status,
    required this.selectedId,
    required this.onOpen,
    required this.onTab,
    this.padding = EdgeInsets.zero,
    this.onAutoSelect,
  });

  final TaskGroup? status;
  final String? selectedId;
  final ValueChanged<WorkCase> onOpen;
  final ValueChanged<TaskGroup?> onTab;

  /// 검색칸·탭과 목록 둘레의 여백.
  final EdgeInsets padding;

  /// 고른 업무가 없을 때 목록을 다 읽으면 보이는 첫 행으로 부릅니다(넓은
  /// 화면). null이면 고르지 않습니다.
  final ValueChanged<WorkCase>? onAutoSelect;

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  late final TaskListMemory _memory = ref.read(taskListMemoryProvider);
  late final _search = TextEditingController(
    text: ref.read(workQueueViewModelProvider).value?.query ?? "",
  );
  final _searchFocus = FocusNode(debugLabel: "업무 검색");
  final _listFocus = FocusNode(debugLabel: "업무 목록");
  final _selectedRow = GlobalKey(debugLabel: "고른 업무 행");
  late ScrollController _scroll = _scrollFor(widget.status);
  Timer? _searchDebounce;
  bool _autoSelected = false;

  ScrollController _scrollFor(TaskGroup? status) {
    final controller = ScrollController(
      initialScrollOffset: _memory.scrollOffsets[status] ?? 0,
    );
    controller.addListener(() {
      if (controller.hasClients) {
        _memory.scrollOffsets[status] = controller.offset;
      }
    });
    return controller;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 다른 화면에서 상단 바 검색을 눌러 Tasks로 온 경우.
      _takeSearchRequest();
      _keepKeyboardFocus();
    });
  }

  @override
  void didUpdateWidget(TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      final old = _scroll;
      _scroll = _scrollFor(widget.status);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _takeSearchRequest() {
    if (!mounted || !ref.read(taskSearchRequestProvider)) return;
    ref.read(taskSearchRequestProvider.notifier).handled();
    _searchFocus.requestFocus();
  }

  /// ↑/↓로 연 업무: 새 목록이 초점을 받고 고른 행이 보이게 합니다.
  void _keepKeyboardFocus() {
    if (!mounted || !_memory.keyboardMoved) return;
    _memory.keyboardMoved = false;
    _listFocus.requestFocus();
    final row = _selectedRow.currentContext;
    if (row == null) return;
    Scrollable.ensureVisible(
      row,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    Scrollable.ensureVisible(
      row,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  /// 목록(행)에 초점이 있을 때 ↑/↓: 이전·다음 행을 엽니다.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (step == 0) return KeyEventResult.ignored;
    final order = taskListOrder(ref, widget.status);
    final at = order.indexWhere((item) => item.id == widget.selectedId);
    final next = at == -1 ? 0 : at + step;
    if (next < 0 || next >= order.length) return KeyEventResult.handled;
    _memory.keyboardMoved = true;
    widget.onOpen(order[next]);
    return KeyEventResult.handled;
  }

  /// 고른 업무가 없으면 보이는 첫 행을 고릅니다. 탭에 필요한 목록을 다 읽은
  /// 뒤 한 번만 합니다. 묶음이 모두 접혀 있으면(처음 상태) 보이는 행이 없어
  /// 고르지 않습니다.
  void _autoSelect({required bool ready}) {
    final onAutoSelect = widget.onAutoSelect;
    if (_autoSelected ||
        !ready ||
        onAutoSelect == null ||
        widget.selectedId != null) {
      return;
    }
    _autoSelected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selectedId != null) return;
      final first = taskListOrder(ref, widget.status).firstOrNull;
      if (first != null) onAutoSelect(first);
    });
  }

  /// One request after typing pauses, not one per key.
  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(workQueueViewModelProvider.notifier).setQuery(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(taskSearchRequestProvider, (_, requested) {
      if (requested) _takeSearchRequest();
    });
    final value = ref.watch(workQueueViewModelProvider);
    final data = value.value;
    final query = data?.query ?? "";
    final completed = ref.watch(completedTasksViewModelProvider(query));
    final counts = data?.counts;
    // 전체 = 보관 전 업무 + 완료(보관) 업무.
    final allCount = counts == null
        ? null
        : counts.total + (completed.value?.total ?? 0);
    final padding = widget.padding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchField(
                controller: _search,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              LdsTabBar<TaskGroup?>(
                expand: true,
                selected: widget.status,
                onSelected: widget.onTab,
                tabs: [
                  LdsTabItem(value: null, label: "전체", count: allCount),
                  LdsTabItem(
                    value: TaskGroup.confirm,
                    label: TaskGroup.confirm.label,
                    count: counts?.confirm,
                  ),
                  LdsTabItem(
                    value: TaskGroup.running,
                    label: TaskGroup.running.label,
                    count: counts?.running,
                  ),
                  LdsTabItem(
                    value: TaskGroup.complete,
                    label: TaskGroup.complete.label,
                    count: completed.value?.total,
                  ),
                ],
              ),
              SizedBox(
                height: 2,
                child: value.isLoading && value.hasValue
                    ? const LinearProgressIndicator(
                        minHeight: 2,
                        color: LdsColors.primary,
                        backgroundColor: Colors.transparent,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        Expanded(child: _list(value, completed)),
      ],
    );
  }

  Widget _list(
    AsyncValue<WorkQueueState> value,
    AsyncValue<CompletedTasks> completedValue,
  ) {
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    if (!value.hasValue) {
      return value.hasError
          ? _Message(
              "업무 목록을 불러오지 못했습니다.",
              action: TextButton(
                onPressed: viewModel.refresh,
                child: const Text("다시 시도"),
              ),
            )
          : const _Loading();
    }
    final data = value.requireValue;
    // 완료(보관된 업무)는 따로 읽은 목록입니다. 전체 탭은 받아 오는 대로
    // 섞고, 완료 탭은 받을 때까지 기다립니다.
    final status = widget.status;
    final onlyCompleted = status == TaskGroup.complete;
    if (onlyCompleted && !completedValue.hasValue) {
      return completedValue.hasError
          ? _Message(
              "완료한 업무를 불러오지 못했습니다.",
              action: TextButton(
                onPressed: () =>
                    ref.invalidate(completedTasksViewModelProvider(data.query)),
                child: const Text("다시 시도"),
              ),
            )
          : const _Loading();
    }
    final withCompleted = status == null || onlyCompleted;
    final done = withCompleted ? completedValue.value : null;
    final groups = groupCases(
      tabCases(status, active: data.items, completed: done?.items),
    );
    _autoSelect(
      ready:
          !viewModel.loadingRest &&
          (!withCompleted || !completedValue.isLoading),
    );
    final activeMore = !onlyCompleted && data.nextCursor != null;
    final completedMore = done?.nextCursor != null;
    // With cases still on the server (pages on their way, or one failed)
    // the tab is not known to be empty: show "더 불러오기" instead.
    if (groups.isEmpty && !activeMore && !completedMore) {
      return _Message(
        status == null && data.query.isEmpty
            ? "아직 도착한 업무가 없습니다."
            : "조건에 맞는 업무가 없습니다.",
      );
    }
    // 고른 업무(주소·검색·Dashboard로 연 것)가 든 묶음은 한 번 펼쳐 보입니다.
    final selectedId = widget.selectedId;
    if (selectedId != null && _memory.revealedId != selectedId) {
      for (final group in groups) {
        if (group.cases.any((item) => item.id == selectedId)) {
          _memory.expanded.add(group.itemName);
          _memory.revealedId = selectedId;
          break;
        }
      }
    }
    final padding = widget.padding;
    final list = CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (final group in groups)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 8),
            sliver: _GroupBox(
              group: group,
              collapsed: !_memory.expanded.contains(group.itemName),
              selectedId: widget.selectedId,
              selectedKey: _selectedRow,
              onOpen: widget.onOpen,
              onToggle: () => setState(() {
                if (!_memory.expanded.remove(group.itemName)) {
                  _memory.expanded.add(group.itemName);
                }
              }),
            ),
          ),
        if (activeMore || completedMore)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding.left),
            sliver: SliverToBoxAdapter(
              child: activeMore
                  ? _LoadMore(
                      loading: data.loadingMore,
                      onPressed: viewModel.loadMore,
                    )
                  : _LoadMore(
                      loading: done!.loadingMore,
                      onPressed: ref
                          .read(
                            completedTasksViewModelProvider(data.query)
                                .notifier,
                          )
                          .loadMore,
                    ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: padding.bottom)),
      ],
    );
    // 목록 안(행)에 초점이 있으면 ↑/↓로 행을 옮깁니다.
    return Focus(focusNode: _listFocus, onKeyEvent: _onKey, child: list);
  }
}

/// 검색칸: 높이 36 (서버 API-01 q: 메일 제목·보낸 사람·품목·요청자).
/// 초점 테두리는 1px `#333D4B`(시안).
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LdsRadius.button),
      borderSide: BorderSide(color: color),
    );
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 15, color: LdsColors.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: "제목·보낸 사람 검색",
          hintStyle: const TextStyle(fontSize: 15, color: LdsColors.disabled),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: LdsColors.muted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: Colors.white,
          border: border(LdsColors.borderStrong),
          enabledBorder: border(LdsColors.borderStrong),
          focusedBorder: border(LdsColors.title),
        ),
      ),
    );
  }
}

/// 품목 묶음 = 상자 하나 (7.13): 1px `#E5E7EA`, 모서리 8, 흰 바탕. 맨 위
/// 머리칸(높이 40)은 스크롤해도 상자 위에 붙어 따라옵니다.
class _GroupBox extends StatelessWidget {
  const _GroupBox({
    required this.group,
    required this.collapsed,
    required this.selectedId,
    required this.selectedKey,
    required this.onOpen,
    required this.onToggle,
  });

  final WorkCaseGroup group;
  final bool collapsed;
  final String? selectedId;

  /// 고른 행에 붙여 ↑/↓로 옮긴 뒤 그 행이 보이게 합니다.
  final GlobalKey selectedKey;
  final ValueChanged<WorkCase> onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cases = group.cases;
    return DecoratedSliver(
      // 테두리는 머리칸·행 바탕 위에 그려야 가려지지 않습니다.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _GroupHeaderDelegate(
              group: group,
              collapsed: collapsed,
              onToggle: onToggle,
            ),
          ),
          if (!collapsed)
            SliverList.separated(
              itemCount: cases.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: LdsColors.lineSoft),
              itemBuilder: (context, index) {
                final workCase = cases[index];
                final selected = workCase.id == selectedId;
                final row = TaskRow(
                  workCase,
                  key: selected ? selectedKey : null,
                  selected: selected,
                  onTap: () => onOpen(workCase),
                );
                // 상자 아래 모서리를 넘지 않게 마지막 행만 깎습니다.
                return index == cases.length - 1
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(LdsRadius.table),
                        ),
                        child: row,
                      )
                    : row;
              },
            ),
        ],
      ),
    );
  }
}

class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _GroupHeaderDelegate({
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  static const height = 40.0;

  final WorkCaseGroup group;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(_GroupHeaderDelegate oldDelegate) =>
      oldDelegate.group != group ||
      oldDelegate.collapsed != collapsed ||
      oldDelegate.onToggle != onToggle;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final name = group.itemName ?? "품목 미확인";
    final count = group.cases.length;
    final radius = collapsed
        ? BorderRadius.circular(LdsRadius.table)
        : const BorderRadius.vertical(top: Radius.circular(LdsRadius.table));
    return Semantics(
      button: true,
      expanded: !collapsed,
      label: "$name $count건, ${collapsed ? "펼치기" : "접기"}",
      excludeSemantics: true,
      child: Material(
        color: LdsColors.canvas,
        borderRadius: radius,
        child: InkWell(
          onTap: onToggle,
          borderRadius: radius,
          child: Container(
            height: height,
            decoration: collapsed
                ? null
                : const BoxDecoration(
                    border: Border(bottom: BorderSide(color: LdsColors.line)),
                  ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // 꺾쇠(아래). 접으면 -90° 돌려 오른쪽을 봅니다.
                AnimatedRotation(
                  turns: collapsed ? -.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: LdsColors.label,
                  ),
                ),
                // 간격 6 + 여백 4: 품목 이름이 행 시작선(40)에 맞습니다.
                const SizedBox(width: 10),
                // 이름 + 건수(이름이 길면 이름만 말줄임).
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: LdsColors.title,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 총 건수: 배지가 아니라 글자입니다(4.2).
                      Text(
                        "$count",
                        style: const TextStyle(
                          fontSize: 15,
                          color: LdsColors.outline,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.expand_more, size: 16),
      label: const Text("더 불러오기", style: TextStyle(fontSize: 13)),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: LdsColors.muted),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}
