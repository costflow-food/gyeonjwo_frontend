import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/work_case.dart";
import "../../domain/work_queue_state.dart";
import "../work_queue_view_model.dart";
import "request_row.dart";

/// 품목별 업무 큐 그룹. 업무를 누르면 메인 화면에 원문이 열립니다.
class QueueGroupList extends ConsumerStatefulWidget {
  const QueueGroupList({super.key, this.shrinkWrap = false});

  /// 스크롤 영역 안(좁은 화면의 메인)에 넣을 때 true.
  final bool shrinkWrap;

  @override
  ConsumerState<QueueGroupList> createState() => _QueueGroupListState();
}

class _QueueGroupListState extends ConsumerState<QueueGroupList> {
  // Groups the user folded. Keyed by item name; null is "품목 미확인".
  final _collapsed = <String?>{};

  void _open(WorkCase workCase) {
    ref.read(workQueueViewModelProvider.notifier).select(workCase.id);
    if (GoRouterState.of(context).uri.path != "/") context.go("/");
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(workQueueViewModelProvider);
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    if (!value.hasValue) {
      if (value.hasError) {
        return _Message(
          "업무 큐를 불러오지 못했어요.",
          action: TextButton(
            onPressed: viewModel.refresh,
            child: const Text("다시 시도"),
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final data = value.requireValue;
    final groups = data.groups;
    if (groups.isEmpty) return const _Message("아직 도착한 업무가 없어요.");
    return ListView(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      children: [
        for (final group in groups) ...[
          _GroupHeader(
            group: group,
            collapsed: _collapsed.contains(group.itemName),
            onToggle: () => setState(() {
              if (!_collapsed.remove(group.itemName)) {
                _collapsed.add(group.itemName);
              }
            }),
          ),
          if (!_collapsed.contains(group.itemName))
            for (final workCase in group.cases)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: RequestRow(
                  workCase,
                  selected: workCase.id == data.selectedId,
                  onTap: () => _open(workCase),
                ),
              ),
          const SizedBox(height: 8),
        ],
        if (data.nextCursor != null)
          _LoadMore(data: data, viewModel: viewModel),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  final WorkCaseGroup group;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Icon(
              collapsed ? Icons.chevron_right : Icons.expand_more,
              size: 18,
              color: muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                group.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.bodyLarge,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (group.waitingCount > 0)
              Tooltip(
                message: "검토를 기다리는 업무",
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: blush,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    "${group.waitingCount}",
                    style: const TextStyle(
                      fontSize: AppFontSizes.caption,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              "${group.cases.length}",
              semanticsLabel: "${group.cases.length}건",
              style: const TextStyle(
                fontSize: AppFontSizes.secondary,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.data, required this.viewModel});

  final WorkQueueState data;
  final WorkQueueViewModel viewModel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: data.loadingMore ? null : viewModel.loadMore,
      icon: data.loadingMore
          ? const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.expand_more, size: 16),
      label: const Text(
        "더 불러오기",
        style: TextStyle(fontSize: AppFontSizes.secondary),
      ),
      style: TextButton.styleFrom(foregroundColor: muted),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: AppFontSizes.secondary,
            color: muted,
          ),
        ),
        ?action,
      ],
    ),
  );
}
