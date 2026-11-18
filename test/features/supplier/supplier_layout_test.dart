import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/app/app_paths.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/supplier/data/supplier_repository_impl.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier_repository.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/supplier_register_dialog.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/supplier_view.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_detail_panel.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_list_row.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart";
import "package:gyeonjwo_frontend/shared/widgets/list_detail_layout.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: "buyer@example.invalid",
  );
}

const _summaries = [
  SupplierSummary(
    id: "s1",
    name: "글로벌베리",
    sourceType: SupplierSourceType.registered,
    itemNames: ["수입 블루베리"],
    location: "부산 강서",
    contactEmail: "sales@berry.example.com",
  ),
  SupplierSummary(
    id: "s2",
    name: "남도냉동",
    sourceType: SupplierSourceType.registered,
    itemNames: ["냉동 망고"],
    location: "전남 나주",
  ),
  SupplierSummary(
    id: "s3",
    name: "다온신선푸드",
    sourceType: SupplierSourceType.verifiedWeb,
    itemNames: ["냉동 딸기", "깐마늘"],
    location: "경기 이천",
  ),
];

class _Repository implements SupplierRepository {
  @override
  Future<SupplierPage> getSuppliers({String query = "", String? cursor}) async {
    final items = [
      for (final summary in _summaries)
        if (query.isEmpty ||
            summary.name.contains(query) ||
            summary.itemNames.any((name) => name.contains(query)))
          summary,
    ];
    return SupplierPage(items: items, total: items.length);
  }

  @override
  Future<SupplierDetail> getSupplier(String supplierId) async {
    final summary = _summaries.firstWhere((s) => s.id == supplierId);
    return SupplierDetail(
      id: summary.id,
      name: summary.name,
      sourceType: summary.sourceType,
      contact: const SupplierContact(name: "담당자"),
      contactEmail: summary.contactEmail,
      location: summary.location,
      items: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 1440,
  TargetPlatform platform = TargetPlatform.windows,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppPaths.suppliers,
    routes: [
      GoRoute(
        path: AppPaths.suppliers,
        builder: (_, _) => const SupplierView(),
      ),
      for (final path in ["/", "/tasks", "/transactions", "/logs", "/account"])
        GoRoute(path: path, builder: (_, _) => Text("page $path")),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionViewModelProvider.overrideWith(_SignedIn.new),
        supplierRepositoryProvider.overrideWithValue(_Repository()),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _listPane => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).color == LdsColors.lineSoft &&
      (widget.decoration! as BoxDecoration).border ==
          const Border(right: BorderSide(color: LdsColors.line)),
);

SupplierListRow _row(WidgetTester tester, int index) =>
    tester.widget<SupplierListRow>(find.byType(SupplierListRow).at(index));

/// 상세 칸의 업체명(21/700 머리).
Finder _detailName(String name) => find.descendant(
  of: find.byType(SupplierDetailPanel),
  matching: find.text(name),
);

void main() {
  testWidgets("wide: list pane 30% beside the detail, no description line", (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text("업체·연락처·취급 품목·인증·기준자료 출처를 확인합니다."), findsNothing);
    // List pane: 30% (400~480) + 24 left + 16 right + 1px line, #F3F4F6,
    // flush against the sidebar.
    expect(_listPane, findsOneWidget);
    expect(
      tester.getSize(_listPane).width,
      ListDetailLayout.listWidth(1440) + 24 + 16 + 1,
    );
    expect(tester.getTopLeft(_listPane).dx, AppSidebar.iconWidth);
    expect(
      tester.getSize(find.byType(ListGroupBox)).width,
      ListDetailLayout.listWidth(1440),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == LdsColors.canvas,
      ),
      findsWidgets,
    );
    // Search, then the count, inside the list pane.
    expect(
      find.descendant(
        of: _listPane,
        matching: find.text("업체명, 품목, 담당자, 지역 검색"),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _listPane, matching: find.textContaining("곳 · 이름순")),
      findsOneWidget,
    );
    // Compact rows, the first one selected and open.
    expect(find.byType(SupplierListRow), findsNWidgets(3));
    expect(_row(tester, 0).selected, isTrue);
    expect(_detailName("글로벌베리"), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(SupplierDetailPanel)).dx,
      greaterThan(tester.getTopRight(_listPane).dx),
    );
    expect(find.byTooltip("거래처 수정"), findsOneWidget);
  });

  testWidgets("refresh and register sit in the top bar, left of search", (
    tester,
  ) async {
    await _pump(tester);
    for (final label in ["새로고침", "거래처 등록"]) {
      final button = find.text(label);
      expect(button, findsOneWidget);
      expect(tester.getCenter(button).dy, lessThan(AppSidebar.headerHeight));
      expect(
        tester.getTopRight(button).dx,
        lessThan(tester.getTopLeft(find.byTooltip("업무 검색")).dx),
      );
    }
    await tester.tap(find.text("거래처 등록"));
    await tester.pumpAndSettle();
    expect(find.byType(SupplierRegisterDialog), findsOneWidget);
  });

  testWidgets("tap a row or use ↑/↓ to open another supplier", (tester) async {
    await _pump(tester);
    await tester.tap(find.text("남도냉동"));
    await tester.pumpAndSettle();
    expect(_row(tester, 1).selected, isTrue);
    expect(_detailName("남도냉동"), findsOneWidget);

    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    await press(LogicalKeyboardKey.arrowDown);
    expect(_detailName("다온신선푸드"), findsOneWidget);
    // A web-verified supplier cannot be edited (KAN-288).
    expect(find.byTooltip("거래처 수정"), findsNothing);
    await press(LogicalKeyboardKey.arrowDown);
    expect(_row(tester, 2).selected, isTrue);
    await press(LogicalKeyboardKey.arrowUp);
    await press(LogicalKeyboardKey.arrowUp);
    expect(_detailName("글로벌베리"), findsOneWidget);
  });

  testWidgets("search still filters the list", (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), "망고");
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(SupplierListRow), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SupplierListRow),
        matching: find.text("남도냉동"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("1100 and narrower: the list alone, then the detail alone", (
    tester,
  ) async {
    await _pump(tester, width: 1000);
    expect(_listPane, findsNothing);
    expect(find.byType(SupplierListRow), findsNWidgets(3));
    expect(find.byType(SupplierDetailPanel), findsNothing);

    await tester.tap(find.text("남도냉동"));
    await tester.pumpAndSettle();
    expect(find.byType(SupplierListRow), findsNothing);
    expect(_detailName("남도냉동"), findsOneWidget);

    await tester.tap(find.text("목록으로"));
    await tester.pumpAndSettle();
    expect(find.byType(SupplierListRow), findsNWidgets(3));
    expect(find.byType(SupplierDetailPanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("phone: the list, a supplier on its own screen", (tester) async {
    await _pump(tester, width: 400, platform: TargetPlatform.android);
    expect(_listPane, findsNothing);
    expect(find.byType(SupplierListRow), findsNWidgets(3));
    // No selection mark on a phone.
    expect(_row(tester, 0).selected, isFalse);
    await tester.tap(find.text("남도냉동"));
    await tester.pumpAndSettle();
    expect(_detailName("남도냉동"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
