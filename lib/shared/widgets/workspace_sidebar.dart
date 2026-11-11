import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_font_sizes.dart';
import '../../features/mail_intake/presentation/mail_intake_view_model.dart';
import '../../features/mail_intake/presentation/widgets/intake_sidebar_list.dart';
import '../../features/work_queue/presentation/widgets/queue_group_list.dart';
import '../../features/work_queue/presentation/work_queue_view_model.dart';
import '../workspace_colors.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({super.key, required this.onCollapse});
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer(
                  builder: (context, ref, _) => IconButton(
                    tooltip: '목록 새로고침',
                    onPressed: () {
                      ref.read(workQueueViewModelProvider.notifier).refresh();
                      ref.read(mailIntakeViewModelProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    color: context.palette.muted,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '업무 큐 접기',
                  onPressed: onCollapse,
                  icon: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: context.palette.ink,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    maximumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: context.palette.surface.withValues(
                      alpha: .5,
                    ),
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Expanded(child: _SidebarTabs()),
          ],
        ),
      ),
    );
  }
}

class _SidebarTabs extends ConsumerStatefulWidget {
  const _SidebarTabs();

  @override
  ConsumerState<_SidebarTabs> createState() => _SidebarTabsState();
}

class _SidebarTabsState extends ConsumerState<_SidebarTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(workQueueViewModelProvider);
    final intake = ref.watch(mailIntakeViewModelProvider);
    // All cases matching the search, whichever status tab is open.
    final queueCount = queue.hasValue ? queue.requireValue.counts.total : null;
    final intakeCount = intake.hasValue
        ? intake.requireValue.totalPending
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          labelColor: context.palette.ink,
          unselectedLabelColor: context.palette.muted,
          indicatorColor: context.palette.accent,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: context.palette.ink.withValues(alpha: 0.2),
          labelPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w500,
          ),
          // Tapping 업무 큐 again goes back to the first screen.
          onTap: (index) {
            if (index == 0 && !_tabs.indexIsChanging) {
              goToQueueHome(context, ref);
            }
          },
          tabs: [
            _CountTab(label: '업무 큐', count: queueCount),
            _CountTab(label: '접수 확인', count: intakeCount),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [QueueGroupList(), IntakeSidebarList()],
          ),
        ),
      ],
    );
  }
}

class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, required this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) => Tab(
    height: 40,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: AppFontSizes.caption,
                fontWeight: FontWeight.w600,
                color: context.palette.muted,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// 첫 화면(업무 큐 요약)으로: 선택한 업무를 닫고 업무 큐로 이동합니다.
void goToQueueHome(BuildContext context, WidgetRef ref) {
  ref.read(workQueueViewModelProvider.notifier).select(null);
  if (GoRouterState.of(context).uri.path != '/') context.go('/');
}
