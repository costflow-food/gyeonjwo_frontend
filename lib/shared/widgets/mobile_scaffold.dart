import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_font_sizes.dart';
import '../workspace_colors.dart';
import 'brand_logo.dart';
import 'workspace_sidebar.dart';

/// Phone layout: the Android app on a narrow screen. Web keeps its own
/// responsive layout at every width.
bool isCompactLayout(BuildContext context) =>
    !kIsWeb && MediaQuery.sizeOf(context).width < 600;

/// A top-level screen on a phone: app bar and the bottom navigation.
class MobileTabScaffold extends StatelessWidget {
  const MobileTabScaffold({
    super.key,
    this.title,
    this.actions = const [],
    required this.body,
  });

  /// Shown in the app bar; the brand logo when null.
  final String? title;
  final List<Widget> actions;

  /// Brings its own scrolling.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    // System back on another tab returns to 업무 큐 instead of leaving the app.
    return PopScope(
      canPop: path == '/',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) => Scaffold(
    backgroundColor: context.palette.canvas,
    appBar: AppBar(
      backgroundColor: context.palette.canvas,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: title == null
          ? const SizedBox(width: 104, height: 34, child: _CompactBrand())
          : Text(
              title!,
              style: const TextStyle(
                fontSize: AppFontSizes.dialogTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
      actions: [...actions, const SizedBox(width: 4)],
    ),
    body: body,
    bottomNavigationBar: const MobileNavigationBar(),
  );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    alignment: Alignment.centerLeft,
    child: SizedBox(width: 118, height: 40, child: const BrandLogo()),
  );
}

/// 업무 큐 / 거래처 / 로그 / 계정 설정.
class MobileNavigationBar extends ConsumerWidget {
  const MobileNavigationBar({super.key});

  static const _paths = ['/', '/suppliers', '/logs', '/account'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = _paths.lastIndexWhere(
      (section) => section != '/' && path.startsWith(section),
    );
    final palette = context.palette;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.blush,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: AppFontSizes.caption,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? palette.ink
                : palette.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? palette.accentText
                : palette.muted,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.line)),
        ),
        child: NavigationBar(
          selectedIndex: index < 0 ? 0 : index,
          onDestinationSelected: (selected) {
            if (selected == 0) {
              goToQueueHome(context, ref);
            } else {
              context.go(_paths[selected]);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: '업무 큐',
            ),
            NavigationDestination(
              icon: Icon(Icons.business_center_outlined),
              selectedIcon: Icon(Icons.business_center),
              label: '거래처',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: '로그',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: '계정 설정',
            ),
          ],
        ),
      ),
    );
  }
}

/// A screen opened from a list on a phone: back button, no bottom navigation,
/// and the screen's main actions pinned to the bottom.
class MobilePageScaffold extends StatelessWidget {
  const MobilePageScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.onBack,
    this.closeIcon = false,
    required this.body,
    this.bottomBar,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;

  /// Defaults to popping this route.
  final VoidCallback? onBack;
  final bool closeIcon;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    if (back == null) return _scaffold(context);
    // A routed screen (opened with go) has nothing under it to pop to.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) => Scaffold(
    backgroundColor: context.palette.canvas,
    appBar: AppBar(
      backgroundColor: context.palette.canvas,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        tooltip: closeIcon ? '닫기' : '뒤로',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: Icon(closeIcon ? Icons.close : Icons.arrow_back),
      ),
      title:
          titleWidget ??
          Text(
            title ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSizes.cardTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
      actions: [...actions, const SizedBox(width: 4)],
    ),
    body: body,
    bottomNavigationBar: bottomBar == null
        ? null
        : MobileActionBar(child: bottomBar!),
  );
}

/// Bottom-pinned area for a screen's main buttons.
class MobileActionBar extends StatelessWidget {
  const MobileActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.palette.surface,
      border: Border(top: BorderSide(color: context.palette.line)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: child,
      ),
    ),
  );
}

/// Full-width, 48px buttons for [MobileActionBar].
abstract final class MobileButtons {
  static ButtonStyle _base(ButtonStyle style) => style.copyWith(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontSize: AppFontSizes.buttonLarge,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ButtonStyle filled(BuildContext context) => _base(
    FilledButton.styleFrom(
      backgroundColor: context.palette.accent,
      foregroundColor: context.palette.onAccent,
      disabledBackgroundColor: context.palette.line,
      disabledForegroundColor: context.palette.muted,
    ),
  );

  static ButtonStyle outlined(BuildContext context) => _base(
    OutlinedButton.styleFrom(
      foregroundColor: context.palette.ink,
      disabledForegroundColor: context.palette.muted,
      side: BorderSide(color: context.palette.ink.withValues(alpha: .6)),
    ),
  );
}
