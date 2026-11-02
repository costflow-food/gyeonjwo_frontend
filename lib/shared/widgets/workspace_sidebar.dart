import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_font_sizes.dart';
import '../../features/auth/presentation/widgets/sign_out_action.dart';
import '../../features/mail_intake/presentation/mail_intake_view_model.dart';
import '../../features/mail_intake/presentation/widgets/intake_sidebar_list.dart';
import '../../features/work_queue/presentation/widgets/queue_group_list.dart';
import '../../features/work_queue/presentation/work_queue_view_model.dart';
import '../workspace_colors.dart';
import 'brand_logo.dart';

/// 왼쪽 사이드바: 품목별 업무 큐 그룹만 둡니다. 실행 로그·거래처는 다른 곳으로 옮깁니다.
class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({super.key, required this.onCollapse});
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Consumer(
                      // No ripple on the logo; just a clickable cursor.
                      builder: (context, ref, _) => MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => goToQueueHome(context, ref),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: BrandLogo(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) => IconButton(
                      tooltip: '목록 새로고침',
                      onPressed: () {
                        ref.read(workQueueViewModelProvider.notifier).refresh();
                        ref.read(mailIntakeViewModelProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      color: muted,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: '사이드바 접기',
                    onPressed: onCollapse,
                    icon: const Icon(Icons.chevron_left, size: 20),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      maximumSize: const Size(36, 36),
                      padding: const EdgeInsets.all(6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'PURCHASING WORKSPACE',
                style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1.1),
              ),
              const SizedBox(height: 28),
              const Expanded(child: _SidebarTabs()),
              const Divider(color: line),
              const SizedBox(height: 8),
              const _AccountRow(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 업무 큐 | 접수 확인. 탭을 누르거나 옆으로 밀어 넘깁니다(설정 화면과 같은 방식).
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
    final queueCount = queue.hasValue ? queue.requireValue.items.length : null;
    final intakeCount = intake.hasValue
        ? intake.requireValue.totalPending
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Each tab takes half the width; counts sit in their own badge.
        TabBar(
          controller: _tabs,
          labelColor: accent,
          unselectedLabelColor: muted,
          indicatorColor: accent,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: line,
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
              color: const Color(0xFFF0F1F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: AppFontSizes.caption,
                fontWeight: FontWeight.w600,
                color: muted,
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

enum _AccountMenu { settings, signOut }

/// 사용자 표시만 하고, 톱니바퀴를 눌러야 설정·로그아웃 메뉴가 열립니다.
class _AccountRow extends ConsumerWidget {
  const _AccountRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: canvas,
            foregroundColor: muted,
            child: Icon(Icons.person_outline, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '구매담당자',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<_AccountMenu>(
            tooltip: '계정 메뉴',
            icon: const Icon(Icons.settings_outlined, size: 18, color: muted),
            position: PopupMenuPosition.over,
            onSelected: (choice) {
              switch (choice) {
                case _AccountMenu.settings:
                  context.go('/account');
                case _AccountMenu.signOut:
                  signOutAndLeave(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccountMenu.settings,
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 16),
                    SizedBox(width: 10),
                    Text('설정', style: TextStyle(fontSize: AppFontSizes.body)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AccountMenu.signOut,
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16),
                    SizedBox(width: 10),
                    Text('로그아웃', style: TextStyle(fontSize: AppFontSizes.body)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
