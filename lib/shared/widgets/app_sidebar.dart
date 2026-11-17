import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_paths.dart';
import '../../features/auth/presentation/auth_session_view_model.dart';
import '../../features/auth/presentation/widgets/sign_out_action.dart';
import '../../features/send_settings/presentation/send_settings_dialog.dart';
import '../lds_colors.dart';
import 'lds/lds.dart';

/// 왼쪽 메뉴 (`docs/design-ssot.md` 7.17). 숫자 배지는 두지 않습니다(4.2).
enum AppMenu {
  dashboard('Dashboard', Icons.grid_view_outlined, AppPaths.dashboard),
  tasks('Tasks', Icons.format_list_bulleted, AppPaths.tasks),
  transactions(
    'Transactions',
    Icons.receipt_long_outlined,
    AppPaths.transactions,
  ),
  suppliers('Suppliers', Icons.storefront_outlined, AppPaths.suppliers);

  const AppMenu(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

/// 사용자가 사이드바를 접거나 편 선택. null이면 화면별 기본값(7.8)을
/// 따르고, 한 번 고르면 화면을 옮겨도 유지합니다.
class SidebarChoice extends Notifier<bool?> {
  @override
  bool? build() => null;

  // ignore: use_setters_to_change_properties
  void choose(bool wide) => state = wide;
}

final sidebarChoiceProvider = NotifierProvider<SidebarChoice, bool?>(
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

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Container(
      width: wide ? wideWidth : iconWidth,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: LdsColors.line)),
      ),
      child: SafeArea(
        right: false,
        child: wide ? _wide(context) : _icons(context),
      ),
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
            LdsIconButton(
              icon: overlay ? Icons.close : Icons.keyboard_double_arrow_left,
              tooltip: overlay ? '메뉴 닫기' : '메뉴 접기',
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
        child: Center(
          child: _Symbol(onTap: () => _go(context, AppPaths.dashboard)),
        ),
      ),
      const SizedBox(height: 16),
      LdsIconButton(
        icon: Icons.keyboard_double_arrow_right,
        tooltip: '메뉴 펼치기',
        onPressed: onToggle,
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

/// 넓은 메뉴의 가로 로고. T 심볼과 같은 주황(7.8.2).
class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '견줘 Dashboard',
    excludeSemantics: true,
    child: LdsFocusRing(
      radius: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/logo.png',
              width: 30,
              height: 30,
              color: LdsColors.primary,
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 6),
            const Text(
              '견줘',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: LdsColors.primary,
                letterSpacing: -.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 아이콘 메뉴 로고 'T' 심볼 30×30 (7.8.2). 전용 에셋이 없어 주황 둥근 사각에
/// 흰 'T'로 그립니다.
class _Symbol extends StatelessWidget {
  const _Symbol({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Dashboard',
    child: Semantics(
      button: true,
      label: '견줘 Dashboard',
      excludeSemantics: true,
      child: LdsFocusRing(
        radius: 8,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LdsColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'T',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
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
                    Icon(menu.icon, size: 22, color: color),
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
              child: Icon(
                menu.icon,
                size: 22,
                color: selected ? LdsColors.primary : LdsColors.label,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

enum _AccountAction { settings, sendSettings, logs, signOut }

/// 아래 계정 카드: 아바타·이름·이메일 + 톱니바퀴 (7.17). 아이콘 메뉴에서는
/// 아바타만. 누르면 계정 메뉴(계정 설정 · 메일 발송 설정 · 실행 로그 · 로그아웃).
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.compact, this.onNavigate});

  final bool compact;
  final VoidCallback? onNavigate;

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
    return Semantics(
      button: true,
      label: '계정 메뉴, $email',
      excludeSemantics: true,
      child: LdsFocusRing(
        radius: compact ? 18 : 8,
        child: PopupMenuButton<_AccountAction>(
          tooltip: '계정 메뉴',
          position: PopupMenuPosition.over,
          offset: const Offset(0, -8),
          borderRadius: BorderRadius.circular(compact ? 18 : 8),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: LdsColors.line),
          ),
          onSelected: (action) {
            onNavigate?.call();
            switch (action) {
              case _AccountAction.settings:
                context.go(AppPaths.account);
              case _AccountAction.sendSettings:
                showSendSettingsDialog(context);
              case _AccountAction.logs:
                context.go(AppPaths.logs);
              case _AccountAction.signOut:
                signOutAndLeave(context, ref);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _AccountAction.settings,
              child: _MenuRow(Icons.manage_accounts_outlined, '계정 설정'),
            ),
            PopupMenuItem(
              value: _AccountAction.sendSettings,
              child: _MenuRow(Icons.outgoing_mail, '메일 발송 설정'),
            ),
            PopupMenuItem(
              value: _AccountAction.logs,
              child: _MenuRow(Icons.history, '실행 로그'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: _AccountAction.signOut,
              child: _MenuRow(Icons.logout, '로그아웃'),
            ),
          ],
          child: compact
              ? avatar
              : Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: LdsColors.line),
                    borderRadius: BorderRadius.circular(8),
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
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: LdsColors.label),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 15, color: LdsColors.ink)),
    ],
  );
}
