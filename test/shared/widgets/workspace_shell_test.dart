import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/widgets/workspace_shell.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: "buyer@example.invalid",
  );
}

Widget _page(String name) => WorkspaceShell(child: Text("page $name"));

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String at,
  double width = 1440,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: at,
    routes: [
      for (final path in [
        "/",
        "/tasks",
        "/transactions",
        "/suppliers",
        "/logs",
        "/account",
      ])
        GoRoute(path: path, builder: (_, _) => _page(path)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authSessionViewModelProvider.overrideWith(_SignedIn.new)],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

double _sidebarWidth(WidgetTester tester) =>
    tester.getSize(find.byType(AppSidebar)).width;

void main() {
  group("sidebar (SSOT 7.8, 7.17)", () {
    testWidgets("Menu stays wide across navigation before the first toggle", (
      tester,
    ) async {
      final router = await _pump(tester, at: "/");
      expect(_sidebarWidth(tester), AppSidebar.wideWidth);
      for (final menu in AppMenu.values) {
        expect(find.text(menu.label), findsWidgets);
      }
      // The top bar names the screen.
      expect(find.text("Dashboard"), findsNWidgets(2));

      router.go("/tasks");
      await tester.pumpAndSettle();
      expect(_sidebarWidth(tester), AppSidebar.wideWidth);
      expect(find.text("page /tasks"), findsOneWidget);
      for (final path in [
        "/transactions",
        "/suppliers",
        "/logs",
        "/account",
        "/",
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(_sidebarWidth(tester), AppSidebar.wideWidth);
      }
    });

    testWidgets("a direct Tasks entry also starts wide", (tester) async {
      await _pump(tester, at: "/tasks");
      expect(_sidebarWidth(tester), AppSidebar.wideWidth);
    });

    testWidgets("the user's fold holds across screens", (tester) async {
      final router = await _pump(tester, at: "/");
      await tester.tap(find.byTooltip("메뉴 접기"));
      await tester.pumpAndSettle();
      expect(_sidebarWidth(tester), AppSidebar.iconWidth);

      for (final path in [
        "/tasks",
        "/transactions",
        "/suppliers",
        "/account",
        "/",
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(_sidebarWidth(tester), AppSidebar.iconWidth);
      }

      await tester.tap(find.byTooltip("메뉴 펼치기"));
      await tester.pumpAndSettle();
      router.go("/tasks");
      await tester.pumpAndSettle();
      expect(_sidebarWidth(tester), AppSidebar.wideWidth);
    });

    testWidgets("the selected menu is orange on #FFEFE5, others plain", (
      tester,
    ) async {
      await _pump(tester, at: "/suppliers");
      expect(_sidebarWidth(tester), AppSidebar.wideWidth);
      Material menu(String label) => tester.widget<Material>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(AppSidebar),
                matching: find.text(label),
              ),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(menu("Suppliers").color, LdsColors.primarySoft);
      expect(menu("Tasks").color, Colors.transparent);
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byType(AppSidebar),
          matching: find.text("Suppliers"),
        ),
      );
      expect(label.style!.color, LdsColors.primary);
    });

    testWidgets("no count badge in the menu", (tester) async {
      await _pump(tester, at: "/");
      expect(
        find.descendant(
          of: find.byType(AppSidebar),
          matching: find.byType(LdsBadge),
        ),
        findsNothing,
      );
    });

    testWidgets("logs and settings are reached from the account menu", (
      tester,
    ) async {
      final router = await _pump(tester, at: "/");
      expect(find.text("buyer@example.invalid"), findsOneWidget);
      await tester.tap(find.byTooltip("계정 메뉴"));
      await tester.pumpAndSettle();
      for (final item in ["계정 설정", "메일 발송 설정", "처리 이력", "로그아웃"]) {
        expect(find.text(item), findsOneWidget);
      }
      await tester.tap(find.text("처리 이력"));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, "/logs");
      expect(find.text("처리 이력"), findsOneWidget);
    });
  });

  group("900px and narrower (SSOT 7.8.5)", () {
    testWidgets("the menu opens over a dimmed page and closes", (tester) async {
      await _pump(tester, at: "/", width: 900);
      expect(find.byType(AppSidebar), findsNothing);

      await tester.tap(find.byTooltip("메뉴 열기"));
      await tester.pumpAndSettle();
      expect(_sidebarWidth(tester), AppSidebar.wideWidth);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == LdsColors.overlay,
        ),
        findsOneWidget,
      );

      // Esc closes it.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AppSidebar), findsNothing);

      // So does a tap outside.
      await tester.tap(find.byTooltip("메뉴 열기"));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(800, 500));
      await tester.pumpAndSettle();
      expect(find.byType(AppSidebar), findsNothing);
    });

    testWidgets("choosing a menu closes it", (tester) async {
      final router = await _pump(tester, at: "/", width: 800);
      await tester.tap(find.byTooltip("메뉴 열기"));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppSidebar),
          matching: find.text("Tasks"),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, "/tasks");
      expect(find.byType(AppSidebar), findsNothing);
    });
  });

  testWidgets("top bar is 64 tall and content starts 24 below it", (
    tester,
  ) async {
    await _pump(tester, at: "/transactions");
    final title = find.text("Invoices").last;
    final bar = find
        .ancestor(of: title, matching: find.byType(Container))
        .first;
    expect(tester.getSize(bar).height, 64);
    expect(
      tester.getTopLeft(find.text("page /transactions")).dy -
          tester.getBottomLeft(bar).dy,
      WorkspaceShell.gutter,
    );
  });
}
