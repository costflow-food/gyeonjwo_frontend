import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_paths.dart';
import '../../features/auth/presentation/account_settings_dialog.dart';
import '../../features/auth/presentation/auth_session_view_model.dart';
import '../../features/auth/presentation/widgets/sign_out_action.dart';
import '../../features/workflow_log/presentation/workflow_log_dialog.dart';
import '../lds_colors.dart';
import 'app_icons.dart';
import 'brand_logo.dart';
import 'lds/lds.dart';

/// 왼쪽 메뉴 (`docs/design-ssot.md` 7.17). 숫자 배지는 두지 않습니다(4.2).
enum AppMenu {
  dashboard('Dashboard', AppIcon.dashboard, AppPaths.dashboard),
  tasks('Tasks', AppIcon.tasks, AppPaths.tasks),
  transactions('Invoices', AppIcon.transactions, AppPaths.transactions),
  suppliers('Suppliers', AppIcon.suppliers, AppPaths.suppliers);

  const AppMenu(this.label, this.icon, this.path);
  final String label;
  final AppIcon icon;
  final String path;
}

/// 메뉴는 펼친 상태로 시작하며, 사용자의 접기·펼치기 선택을 화면 이동 중 유지합니다.
class SidebarChoice extends Notifier<bool> {
  @override
  bool build() => true;

  // ignore: use_setters_to_change_properties
  void choose(bool wide) => state = wide;
}

final sidebarChoiceProvider = NotifierProvider<SidebarChoice, bool>(
  SidebarChoice.new,
);

/// 사이드바 (`docs/design-ssot.md` 7.8): 넓은 메뉴 272 · 아이콘 메뉴 64.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.wide,
    required this.selected,
    required this.onToggle,
    this.overlay = false,
    this.onNavigate,
  });

  static const wideWidth = 272.0;
  static const iconWidth = 64.0;

  /// 상단 바와 같은 높이: 로고 줄.
  static const headerHeight = 64.0;

  final bool wide;
  final AppMenu? selected;

  /// 넓은 메뉴 ↔ 아이콘 메뉴. [overlay]면 덮개를 닫습니다.
  final VoidCallback onToggle;

  /// 900px 이하에서 덮개로 연 사이드바.
  final bool overlay;

  /// 메뉴·로고를 누른 뒤. 덮개를 닫는 데 씁니다.
  final VoidCallback? onNavigate;

  void _go(BuildContext context, String path) {
    onNavigate?.call();
    context.go(path);
  }

  /// 펼치기·접기: 폭이 이 시간 동안 바뀌고, 그 사이 두 메뉴가 엇갈려 나타납니다.
  static const toggleDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: _FoldingRail(
      wide: wide,
      wideMenu: () => _wide(context),
      iconMenu: () => _icons(context),
    ),
  );

  Widget _wide(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: headerHeight,
        child: Row(
          children: [
            const SizedBox(width: 20),
            _Logo(onTap: () => _go(context, AppPaths.dashboard)),
            const Spacer(),
            overlay
                ? LdsIconButton(
                    icon: Icons.close,
                    tooltip: '메뉴 닫기',
                    onPressed: onToggle,
                  )
                : LdsIconButton(
                    iconWidget: const AppIconView(
                      AppIcon.sidebarCollapse,
                      size: 20,
                    ),
                    tooltip: '메뉴 접기',
                    borderless: true,
                    onPressed: onToggle,
                  ),
            const SizedBox(width: 14),
          ],
        ),
      ),
      const SizedBox(height: 24),
      for (final menu in AppMenu.values) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _MenuItem(
            menu: menu,
            selected: menu == selected,
            onTap: () => _go(context, menu.path),
          ),
        ),
        const SizedBox(height: 6),
      ],
      const Spacer(),
      Padding(
        padding: const EdgeInsets.all(12),
        child: _AccountCard(compact: false, onNavigate: onNavigate),
      ),
    ],
  );

  Widget _icons(BuildContext context) => Column(
    children: [
      SizedBox(
        height: headerHeight,
        child: Center(child: _RailToggle(onToggle: onToggle)),
      ),
      const SizedBox(height: 24),
      for (final menu in AppMenu.values) ...[
        _MenuIcon(
          menu: menu,
          selected: menu == selected,
          onTap: () => _go(context, menu.path),
        ),
        const SizedBox(height: 6),
      ],
      const Spacer(),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _AccountCard(compact: true, onNavigate: onNavigate),
      ),
    ],
  );
}

/// 넓은 메뉴(1) ↔ 아이콘 메뉴(0)를 컨트롤러 하나로 움직입니다. 폭과 두 메뉴의
/// 투명도가 같은 값을 따라가므로, 도중에 다시 눌러도 지금 자리에서 되돌아갑니다.
/// 움직이는 0.2초 동안은 누를 수 없고, 다 끝나면 한 메뉴만 남습니다.
class _FoldingRail extends StatefulWidget {
  const _FoldingRail({
    required this.wide,
    required this.wideMenu,
    required this.iconMenu,
  });

  final bool wide;
  final Widget Function() wideMenu;
  final Widget Function() iconMenu;

  @override
  State<_FoldingRail> createState() => _FoldingRailState();
}

class _FoldingRailState extends State<_FoldingRail>
    with SingleTickerProviderStateMixin {
  static const _border = BorderSide(color: LdsColors.line);

  late final _fold = AnimationController(
    vsync: this,
    duration: AppSidebar.toggleDuration,
    value: widget.wide ? 1 : 0,
  );
  bool _reduceMotion = false;

  @override
  void didUpdateWidget(_FoldingRail old) {
    super.didUpdateWidget(old);
    if (old.wide == widget.wide) return;
    final target = widget.wide ? 1.0 : 0.0;
    if (_reduceMotion) {
      _fold.value = target;
    } else {
      _fold.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _fold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _fold,
      builder: (context, _) {
        final t = _fold.value;
        return Container(
          width: lerpDouble(AppSidebar.iconWidth, AppSidebar.wideWidth, t),
          decoration: const BoxDecoration(border: Border(right: _border)),
          child: ClipRect(
            child: IgnorePointer(
              ignoring: _fold.isAnimating,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (t < 1)
                    _layer(
                      'icons',
                      AppSidebar.iconWidth,
                      1 - t,
                      shown: !widget.wide,
                      child: widget.iconMenu(),
                    ),
                  if (t > 0)
                    _layer(
                      'wide',
                      AppSidebar.wideWidth,
                      t,
                      shown: widget.wide,
                      child: widget.wideMenu(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 각 메뉴는 늘 제 폭으로 그리고(넘치는 쪽은 잘림), 사라지는 메뉴는 포커스·
  /// 화면 낭독기·툴팁에서 뺍니다.
  static Widget _layer(
    String name,
    double width,
    double opacity, {
    required bool shown,
    required Widget child,
  }) => KeyedSubtree(
    key: ValueKey(name),
    child: OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: width - _border.width,
      maxWidth: width - _border.width,
      child: Opacity(
        opacity: opacity,
        child: ExcludeFocus(
          excluding: !shown,
          child: ExcludeSemantics(
            excluding: !shown,
            child: TooltipVisibility(
              visible: shown,
              child: SafeArea(right: false, child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 넓은 메뉴의 가로 로고. T 심볼과 같은 주황(7.8.2).
class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Thoner Dashboard',
    excludeSemantics: true,
    child: LdsFocusRing(
      radius: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: BrandLogo(height: 28),
        ),
      ),
    ),
  );
}

/// 아이콘 메뉴 로고: 로고의 'T' 글자(주황, 높이 30) (7.8.2).
class _Symbol extends StatelessWidget {
  const _Symbol({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Dashboard',
    child: Semantics(
      button: true,
      label: 'Thoner Dashboard',
      excludeSemantics: true,
      child: LdsFocusRing(
        radius: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              'assets/branding/thoner_symbol.png',
              height: 30,
              color: LdsColors.primary,
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 넓은 메뉴 항목: 높이 50, 모서리 8, 아이콘-글자 14, 글자 15 `#4E5968`.
/// 선택 = 바탕 `#FFEFE5` + 글자·아이콘 `#FF6000` (7.8.4).
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.menu,
    required this.selected,
    required this.onTap,
  });

  final AppMenu menu;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? LdsColors.primary : LdsColors.label;
    return Semantics(
      selected: selected,
      button: true,
      label: menu.label,
      excludeSemantics: true,
      child: LdsFocusRing(
        child: Material(
          color: selected ? LdsColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: selected ? Colors.transparent : LdsColors.canvas,
            child: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    AppIconView(menu.icon, size: 22, color: color),
                    const SizedBox(width: 14),
                    Text(
                      menu.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 아이콘 메뉴 항목 44×44. 이름은 툴팁과 화면 낭독기로 알립니다.
class _MenuIcon extends StatelessWidget {
  const _MenuIcon({
    required this.menu,
    required this.selected,
    required this.onTap,
  });

  final AppMenu menu;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: menu.label,
    child: Semantics(
      selected: selected,
      button: true,
      label: menu.label,
      excludeSemantics: true,
      child: LdsFocusRing(
        child: Material(
          color: selected ? LdsColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: selected ? Colors.transparent : LdsColors.canvas,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: AppIconView(
                  menu.icon,
                  size: 22,
                  color: selected ? LdsColors.primary : LdsColors.label,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

enum _AccountAction { settings, logs, signOut }

/// 아래 계정 카드: 아바타·이름·이메일 + 톱니바퀴 (7.17). 아이콘 메뉴에서는
/// 아바타만. 누르면 계정 메뉴(맨 위 '구매담당자'·이메일, 계정 설정 · 처리 이력 ·
/// 로그아웃). 메일 발송 설정은 계정 설정 팝업의 탭에 있습니다. 넓은 메뉴는
/// 카드 바로 위에 카드와 같은 폭으로, 아이콘 메뉴는 아바타 오른쪽 옆에 아래를
/// 맞춰 띄웁니다.
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.compact, this.onNavigate});

  final bool compact;
  final VoidCallback? onNavigate;

  /// 아이콘 메뉴에서 옆에 띄우는 창 폭.
  static const _besideWidth = 240.0;

  Future<void> _open(BuildContext context, WidgetRef ref, String email) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final action = await Navigator.of(context).push(
      _AccountMenuRoute(
        anchor: anchor,
        beside: compact,
        child: _AccountMenu(
          email: email,
          width: compact ? _besideWidth : anchor.width,
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final location = GoRouterState.of(context).uri.toString();
    final navigator = Navigator.of(context);
    final closingOverlay = onNavigate != null;
    onNavigate?.call();

    /// 팝업 열기. 덮개 메뉴(900px 이하)에서 고르면 덮개가 사라진 다음 프레임에
    /// 열어야 키보드 포커스가 팝업에 들어갑니다(같은 프레임이면 덮개의 포커스
    /// 범위가 치워지며 포커스가 뒤 화면으로 돌아가 Esc·Tab이 팝업에 닿지 않음).
    /// 그때는 이 카드도 사라지므로 Navigator의 context로 엽니다.
    void openPopup(void Function(BuildContext context) show) {
      if (!closingOverlay) {
        show(context);
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) show(navigator.context);
      });
    }

    switch (action) {
      case _AccountAction.settings:
        openPopup(
          (context) => showAccountSettingsDialog(context, returnTo: location),
        );
      case _AccountAction.logs:
        openPopup(showWorkflowLogDialog);
      case _AccountAction.signOut:
        signOutAndLeave(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authSessionViewModelProvider).value?.email ?? '';
    final name = email.contains('@') ? email.split('@').first : '내 계정';
    final avatar = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: LdsColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        textScaler: TextScaler.noScaling,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
    final radius = BorderRadius.circular(compact ? 18 : 8);
    return Semantics(
      button: true,
      label: '계정 메뉴, $email',
      excludeSemantics: true,
      child: LdsFocusRing(
        radius: compact ? 18 : 8,
        child: Tooltip(
          message: '계정 메뉴',
          child: Builder(
            builder: (context) => InkWell(
              onTap: () => _open(context, ref, email),
              borderRadius: radius,
              child: compact
                  ? avatar
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: LdsColors.line),
                        borderRadius: radius,
                      ),
                      child: Row(
                        children: [
                          avatar,
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: LdsColors.ink,
                                  ),
                                ),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: LdsColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: LdsColors.label,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 계정 메뉴 창: 흰 바탕, 모서리 12, 1px `#E5E7EA`. 바깥·Esc로 닫습니다.
class _AccountMenuRoute extends PopupRoute<_AccountAction> {
  _AccountMenuRoute({
    required this.anchor,
    required this.beside,
    required this.child,
  });

  final Rect anchor;

  /// true면 아바타 오른쪽 옆, false면 카드 바로 위.
  final bool beside;
  final Widget child;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '계정 메뉴 닫기';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => CustomSingleChildLayout(
    delegate: _AccountMenuLayout(anchor, beside: beside),
    child: Material(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: LdsColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

class _AccountMenuLayout extends SingleChildLayoutDelegate {
  const _AccountMenuLayout(this.anchor, {required this.beside});

  final Rect anchor;
  final bool beside;

  static const _gap = 8.0;
  static const _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest)
          .deflate(const EdgeInsets.all(_margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = beside ? anchor.right + _gap : anchor.left;
    final y = beside
        ? anchor.bottom - childSize.height
        : anchor.top - _gap - childSize.height;
    return Offset(
      x.clamp(_margin, size.width - childSize.width - _margin).toDouble(),
      y.clamp(_margin, size.height - childSize.height - _margin).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_AccountMenuLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.beside != beside;
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.email, required this.width});

  final String email;
  final double width;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(context).maybePop(),
    },
    child: FocusScope(
      autofocus: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구매담당자',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.ink,
                    ),
                  ),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: LdsColors.line),
            const SizedBox(height: 4),
            const _MenuRow(
              _AccountAction.settings,
              Icons.manage_accounts_outlined,
              '계정 설정',
            ),
            const _MenuRow(_AccountAction.logs, Icons.history, '처리 이력'),
            const SizedBox(height: 4),
            const Divider(height: 1, color: LdsColors.line),
            const SizedBox(height: 4),
            const _MenuRow(_AccountAction.signOut, Icons.logout, '로그아웃'),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.action, this.icon, this.label);

  final _AccountAction action;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).pop(action),
    hoverColor: LdsColors.canvas,
    child: SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: LdsColors.label),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: LdsColors.ink),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 로고 자리에서만 펼치기: 포인터 hover 또는 키보드 포커스일 때 아이콘 전환.
class _RailToggle extends StatefulWidget {
  const _RailToggle({required this.onToggle});
  final VoidCallback onToggle;
  @override
  State<_RailToggle> createState() => _RailToggleState();
}

class _RailToggleState extends State<_RailToggle> {
  bool _hover = false, _focus = false;
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    onShowFocusHighlight: (v) => setState(() => _focus = v),
    onShowHoverHighlight: (v) => setState(() => _hover = v),
    child: Tooltip(
      message: '메뉴 펼치기',
      child: LdsFocusRing(
        radius: 8,
        child: InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 36,
            child: Center(
              child: _hover || _focus
                  ? const AppIconView(AppIcon.sidebarExpand, size: 20)
                  : IgnorePointer(child: _Symbol(onTap: widget.onToggle)),
            ),
          ),
        ),
      ),
    ),
  );
}
