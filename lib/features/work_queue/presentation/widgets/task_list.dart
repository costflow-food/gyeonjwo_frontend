import "dart:async";

import "package:flutter/material.dart";
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

  /// 접은 품목 묶음. null은 '품목 미확인'입니다.
  final collapsed = <String?>{};
}

final taskListMemoryProvider = Provider<TaskListMemory>(
  (ref) => TaskListMemory(),
);

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
  });

  final TaskGroup? status;
  final String? selectedId;
  final ValueChanged<WorkCase> onOpen;
  final ValueChanged<TaskGroup?> onTab;

  /// 검색칸·탭과 목록 둘레의 여백.
  final EdgeInsets padding;

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  late final TaskListMemory _memory = ref.read(taskListMemoryProvider);
  late final _search = TextEditingController(
    text: ref.read(workQueueViewModelProvider).value?.query ?? "",
  );
  final _searchFocus = FocusNode(debugLabel: "업무 검색");
  late ScrollController _scroll = _scrollFor(widget.status);
  Timer? _searchDebounce;

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
    // 다른 화면에서 상단 바 검색을 눌러 Tasks로 온 경우.
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeSearchRequest());
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
    _scroll.dispose();
    super.dispose();
  }

  void _takeSearchRequest() {
    if (!mounted || !ref.read(taskSearchRequestProvider)) return;
    ref.read(taskSearchRequestProvider.notifier).handled();
    _searchFocus.requestFocus();
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
                selected: widget.status,
                onSelected: widget.onTab,
                tabs: [
                  LdsTabItem(value: null, label: "전체", count: counts?.total),
                  LdsTabItem(
                    value: TaskGroup.confirm,
                    label: TaskGroup.confirm.label,
                    count: counts?.confirm,
                    urgent: true,
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
    // 완료(보관된 업무)는 따로 읽은 목록입니다.
    final showCompleted = widget.status == TaskGroup.complete;
    if (showCompleted && !completedValue.hasValue) {
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
    final done = showCompleted ? completedValue.requireValue : null;
    final groups = done == null
        ? groupCases([
            for (final workCase in data.items)
              if (widget.status == null ||
                  taskGroupOf(workCase) == widget.status)
                workCase,
          ])
        : groupCases(done.items);
    final hasMore = done == null
        ? data.nextCursor != null
        : done.nextCursor != null;
    // With cases still on the server (pages on their way, or one failed)
    // the tab is not known to be empty: show "더 불러오기" instead.
    if (groups.isEmpty && !hasMore) {
      return _Message(
        widget.status == null && data.query.isEmpty
            ? "아직 도착한 업무가 없습니다."
            : "조건에 맞는 업무가 없습니다.",
      );
    }
    final padding = widget.padding;
    return CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (final group in groups)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 8),
            sliver: _GroupBox(
              group: group,
              collapsed: _memory.collapsed.contains(group.itemName),
              selectedId: widget.selectedId,
              onOpen: widget.onOpen,
              onToggle: () => setState(() {
                if (!_memory.collapsed.remove(group.itemName)) {
                  _memory.collapsed.add(group.itemName);
                }
              }),
            ),
          ),
        if (hasMore)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: padding.left),
            sliver: SliverToBoxAdapter(
              child: done == null
                  ? _LoadMore(
                      loading: data.loadingMore,
                      onPressed: viewModel.loadMore,
                    )
                  : _LoadMore(
                      loading: done.loadingMore,
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
  }
}

/// 검색칸: 높이 36, 거래처·품목·메일 제목 (서버 API-01 q).
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
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(LdsRadius.button),
          borderSide: BorderSide(color: color, width: width),
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
          hintText: "거래처 · 품목 · 메일 제목 검색",
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
          focusedBorder: border(LdsColors.primary, 2),
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
    required this.onOpen,
    required this.onToggle,
  });

  final WorkCaseGroup group;
  final bool collapsed;
  final String? selectedId;
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
                final row = TaskRow(
                  workCase,
                  selected: workCase.id == selectedId,
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
                Icon(
                  collapsed ? Icons.arrow_right : Icons.arrow_drop_down,
                  size: 18,
                  color: LdsColors.label,
                ),
                // 간격 6 + 여백 4: 품목 이름이 행 시작선(40)에 맞습니다.
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.title,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 총 건수: 배지가 아니라 글자입니다(4.2).
                Text(
                  "$count",
                  style: const TextStyle(fontSize: 13, color: LdsColors.muted),
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
