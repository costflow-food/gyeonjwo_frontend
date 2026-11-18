import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_paths.dart';
import '../../features/work_queue/presentation/task_search_request.dart';
import '../lds_colors.dart';
import 'app_sidebar.dart';
import 'lds/lds.dart';
import 'mobile_scaffold.dart';

/// 화면 주소별 상단 바 제목, 선택된 메뉴, 사이드바 시작 모양 (7.8, 7.17).
class AppSection {
  const AppSection(this.title, this.menu, {required this.startsWide});

  final String title;

  /// 메뉴에 없는 화면(실행 로그·설정)은 null: 선택 표시가 없습니다.
  final AppMenu? menu;

  /// 둘러보는 화면은 넓은 메뉴로, 작업 화면(Tasks·검토 카드·Suppliers)은
  /// 아이콘 메뉴로 시작합니다.
  final bool startsWide;

  static AppSection of(String path) {
    bool under(String root) => path == root || path.startsWith('$root/');
    if (under(AppPaths.tasks)) {
      // 검토 카드(/tasks/:id/review)는 화면 제목을 따로 둡니다.
      return AppSection(
        path.endsWith('/review') ? '검토 카드' : 'Tasks',
        AppMenu.tasks,
        startsWide: false,
      );
    }
    if (under(AppPaths.transactions)) {
      return const AppSection(
        'Transactions',
        AppMenu.transactions,
        startsWide: true,
      );
    }
    if (under(AppPaths.suppliers)) {
      return const AppSection(
        'Suppliers',
        AppMenu.suppliers,
        startsWide: false,
      );
    }
    if (under(AppPaths.logs)) {
      return const AppSection('실행 로그', null, startsWide: true);
    }
    if (under(AppPaths.account)) {
      return const AppSection('설정', null, startsWide: true);
    }
    return const AppSection('Dashboard', AppMenu.dashboard, startsWide: true);
  }
}

/// 앱 틀: 사이드바 + 상단 바 + 본문 (`docs/design-ssot.md` 7.6, 7.8).
///
/// 900px 이하에서는 사이드바를 숨기고 상단 바의 메뉴 버튼으로 덮개를 엽니다.
/// 휴대폰(Android 좁은 화면)은 [MobileTabScaffold]를 씁니다.
class WorkspaceShell extends ConsumerStatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.child,
    this.scrollable = true,
    this.topAction,
  });

  /// 이 폭 이하에서는 사이드바가 덮개로 열립니다(7.8.1, 7.8.5).
  static const overlayWidth = 900.0;

  /// 헤더 아래 첫 콘텐츠와 좌우 여백(7.6).
  static const gutter = 24.0;

  final Widget child;

  /// false면 [child]가 스크롤과 여백을 직접 둡니다(Tasks 목록·상세).
  final bool scrollable;

  /// 상단 바 오른쪽, 검색 왼쪽(예: Dashboard 기간 선택, 7.9.2).
  final Widget? topAction;

  @override
  ConsumerState<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends ConsumerState<WorkspaceShell> {
  bool _overlayOpen = false;

  void _setOverlay(bool open) {
    if (_overlayOpen != open) setState(() => _overlayOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    final section = AppSection.of(GoRouterState.of(context).uri.path);
    if (isCompactLayout(context)) {
      return MobileTabScaffold(
        title: section.menu == AppMenu.dashboard ? null : section.title,
        body: widget.scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: widget.child,
              )
            : widget.child,
      );
    }
    final wide = ref.watch(sidebarChoiceProvider) ?? section.startsWide;
    final body = widget.scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(WorkspaceShell.gutter),
            child: widget.child,
          )
        : widget.child;
    return Scaffold(
      backgroundColor: LdsColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final overlayMode =
              constraints.maxWidth <= WorkspaceShell.overlayWidth;
          final page = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!overlayMode)
                AppSidebar(
                  wide: wide,
                  selected: section.menu,
                  onToggle: () =>
                      ref.read(sidebarChoiceProvider.notifier).choose(!wide),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      title: section.title,
                      onMenu: overlayMode ? () => _setOverlay(true) : null,
                      action: widget.topAction,
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          );
          if (!overlayMode || !_overlayOpen) return page;
          return Stack(
            children: [
              page,
              Positioned.fill(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): () =>
                        _setOverlay(false),
                  },
                  child: FocusScope(
                    autofocus: true,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Semantics(
                            button: true,
                            label: '메뉴 닫기',
                            child: GestureDetector(
                              onTap: () => _setOverlay(false),
                              child: const ColoredBox(color: LdsColors.overlay),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: AppSidebar(
                            wide: true,
                            overlay: true,
                            selected: section.menu,
                            onToggle: () => _setOverlay(false),
                            onNavigate: () => _setOverlay(false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 상단 바: 높이 64, 흰 바탕, 아래 1px `#E5E7EA`, 좌우 24. 화면 제목 24/700,
/// 오른쪽 [action](기간 선택 등) · 검색 · 알림 (3-2, 7.9.2).
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title, this.onMenu, this.action});

  final String title;
  final Widget? action;

  /// 900px 이하: 제목 왼쪽 메뉴 열기 버튼.
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    height: AppSidebar.headerHeight,
    padding: const EdgeInsets.symmetric(horizontal: WorkspaceShell.gutter),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: LdsColors.line)),
    ),
    child: Row(
      children: [
        if (onMenu != null) ...[
          LdsIconButton(icon: Icons.menu, tooltip: '메뉴 열기', onPressed: onMenu),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: LdsColors.ink,
              ),
            ),
          ),
        ),
        if (action case final action?) ...[
          const SizedBox(width: 12),
          action,
          const SizedBox(width: 8),
        ],
        LdsIconButton(
          icon: Icons.search,
          tooltip: '업무 검색',
          onPressed: () {
            ref.read(taskSearchRequestProvider.notifier).request();
            final path = GoRouterState.of(context).uri.path;
            if (!path.startsWith(AppPaths.tasks)) context.go(AppPaths.tasks);
          },
        ),
        const SizedBox(width: 8),
        // 알림 기능이 아직 없어 비활성으로 둡니다.
        const LdsIconButton(
          icon: Icons.notifications_none,
          tooltip: '알림 (준비 중)',
          onPressed: null,
        ),
      ],
    ),
  );
}
