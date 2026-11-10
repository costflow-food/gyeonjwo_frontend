import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/widgets/sign_out_action.dart';
import '../app_font_sizes.dart';
import '../workspace_colors.dart';
import 'brand_logo.dart';
import 'workspace_sidebar.dart';

/// 위쪽 메뉴 줄 + 왼쪽 업무 큐 + 가운데 작업 판. 메뉴를 위로 올려 좌우 폭을 넓게 씁니다.
class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key, required this.child});
  final Widget child;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  static const _minimumBodyWidth = 280.0;
  static const _collapsedSidebarWidth = 56.0;

  // Keep the user's choice separate from the space available to display it.
  bool _sidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.frame,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Wide enough for the four status filters on one line.
                  final sidebarWidth = (constraints.maxWidth * .22).clamp(
                    330.0,
                    360.0,
                  );
                  final canExpandSidebar =
                      constraints.maxWidth >= sidebarWidth + _minimumBodyWidth;
                  final showSidebar = _sidebarOpen && canExpandSidebar;
                  final showCollapsedSidebar =
                      !showSidebar &&
                      constraints.maxWidth >=
                          _collapsedSidebarWidth + _minimumBodyWidth;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showSidebar)
                        SizedBox(
                          width: sidebarWidth,
                          child: WorkspaceSidebar(
                            onCollapse: () =>
                                setState(() => _sidebarOpen = false),
                          ),
                        )
                      else if (showCollapsedSidebar)
                        SizedBox(
                          width: _collapsedSidebarWidth,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: IconButton(
                              tooltip: canExpandSidebar
                                  ? '업무 큐 펼치기'
                                  : '창을 넓히면 업무 큐를 펼칠 수 있습니다',
                              onPressed: canExpandSidebar
                                  ? () => setState(() => _sidebarOpen = true)
                                  : null,
                              icon: Icon(
                                Icons.menu,
                                color: context.palette.ink,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            showSidebar || showCollapsedSidebar ? 0 : 16,
                            0,
                            16,
                            16,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.palette.panel,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [Expanded(child: _body())],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() => LayoutBuilder(
    builder: (context, viewport) {
      final padding = (viewport.maxWidth * .03).clamp(16.0, 32.0);
      final content = SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: widget.child,
      );
      if (viewport.maxWidth >= _minimumBodyWidth) {
        return content;
      }
      // Preserve readable content in extremely narrow windows.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _minimumBodyWidth,
          height: viewport.maxHeight,
          child: content,
        ),
      );
    },
  );
}

/// 로고 · 업무 큐/거래처/실행 로그 · 계정 메뉴.
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final section = path.startsWith('/suppliers')
        ? '/suppliers'
        : path.startsWith('/logs')
        ? '/logs'
        : path.startsWith('/account')
        ? '/account'
        : '/';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => goToQueueHome(context, ref),
              child: const SizedBox(width: 118, height: 40, child: BrandLogo()),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.palette.surface.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavTab(
                        label: '업무 큐',
                        icon: Icons.grid_view_rounded,
                        selected: section == '/',
                        onTap: () => goToQueueHome(context, ref),
                      ),
                      _NavTab(
                        label: '거래처',
                        icon: Icons.business_center_outlined,
                        selected: section == '/suppliers',
                        onTap: () => context.go('/suppliers'),
                      ),
                      _NavTab(
                        label: '실행 로그',
                        icon: Icons.receipt_long_outlined,
                        selected: section == '/logs',
                        onTap: () => context.go('/logs'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const _AccountButton(),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? context.palette.accent : Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? context.palette.onAccent
                    : context.palette.ink,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSizes.navigation,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? context.palette.onAccent
                      : context.palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum _AccountMenu { settings, signOut }

/// 오른쪽 끝 계정 버튼: 설정·로그아웃.
class _AccountButton extends ConsumerWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<_AccountMenu>(
        tooltip: '계정 메뉴',
        position: PopupMenuPosition.under,
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
                Text('계정 설정', style: TextStyle(fontSize: AppFontSizes.body)),
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
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.palette.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.palette.ink.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.person, size: 20, color: context.palette.ink),
        ),
      );
}
