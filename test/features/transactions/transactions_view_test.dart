import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/app/app_paths.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_item_card.dart";
import "package:gyeonjwo_frontend/features/transactions/data/transaction_sample_repository.dart";
import "package:gyeonjwo_frontend/features/transactions/domain/purchase_record.dart";
import "package:gyeonjwo_frontend/features/transactions/domain/transaction_listing.dart";
import "package:gyeonjwo_frontend/features/transactions/domain/transaction_repository.dart";
import "package:gyeonjwo_frontend/features/transactions/presentation/transactions_view.dart";
import "package:gyeonjwo_frontend/features/transactions/presentation/transactions_view_model.dart";
import "package:gyeonjwo_frontend/features/transactions/presentation/widgets/transaction_detail_panel.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: "buyer@example.invalid",
  );
}

class _Records implements TransactionRepository {
  const _Records(this.records);

  final List<PurchaseRecord> records;

  @override
  Future<List<PurchaseRecord>> getPurchases() async => records;
}

PurchaseRecord _record(String id, String date, int price) => PurchaseRecord(
  id: id,
  supplierItemId: "item-$id",
  supplierId: "supplier-$id",
  itemName: "냉동 망고",
  specification: "다이스 / 1kg",
  supplierName: "업체$id",
  transactionDate: date,
  quantity: 100,
  unit: "kg",
  unitPrice: price,
  totalAmount: price * 100,
  currency: "KRW",
);

final _today = DateTime(2026, 11, 18);

Future<GoRouter> _pump(
  WidgetTester tester, {
  String at = "/transactions",
  double width = 1440,
  TargetPlatform platform = TargetPlatform.windows,
  List<PurchaseRecord>? records,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(
        path: AppPaths.transactions,
        builder: (context, state) => TransactionsView(
          entry: TransactionsEntry(
            supplierItemId: state.uri.queryParameters["supplier_item"],
            itemName: state.uri.queryParameters["item"],
            date: state.uri.queryParameters["date"],
          ),
        ),
      ),
      for (final path in ["/", "/tasks", "/suppliers", "/logs", "/account"])
        GoRoute(path: path, builder: (_, _) => Text("page $path")),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionViewModelProvider.overrideWith(_SignedIn.new),
        transactionsTodayProvider.overrideWithValue(_today),
        if (records != null)
          transactionRepositoryProvider.overrideWithValue(_Records(records)),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// 화면에 보이는 순서(위→아래)대로 확정일.
List<String> _dates(WidgetTester tester) {
  final finder = find.textContaining(RegExp(r"^2026\.\d\d\.\d\d$"));
  final found = finder.evaluate().toList()
    ..sort(
      (a, b) => tester
          .getTopLeft(find.byWidget(a.widget))
          .dy
          .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy),
    );
  return [for (final element in found) (element.widget as Text).data!];
}

Finder _head(String label) => find.bySemanticsLabel(RegExp("^$label, "));

void main() {
  testWidgets("기본 기간은 최근 3개월, 머리는 건수·총액", (tester) async {
    await _pump(tester);
    final button = tester.widget<LdsDateRangeButton>(
      find.byType(LdsDateRangeButton),
    );
    expect(button.value.start, DateTime(2026, 8, 19));
    expect(button.value.end, DateTime(2026, 11, 18));
    expect(find.text("2026. 8. 19 - 2026. 11. 18"), findsOneWidget);
    expect(
      find.text("Thoner에서 확정됐거나 증빙이 등록된 거래를 기간·품목·거래처로 찾아봅니다."),
      findsOneWidget,
    );
    expect(find.text("확정 거래 5건 · 총 18,000,000원"), findsOneWidget);
    // DB에 없는 확정 방식 열·필터는 없습니다.
    expect(find.text("확정 방식"), findsNothing);
    expect(find.text("품목"), findsWidgets);
    expect(find.text("거래처"), findsWidgets);
  });

  testWidgets("작업 화면이라 사이드바는 아이콘 메뉴로 시작", (tester) async {
    await _pump(tester);
    expect(tester.getSize(find.byType(AppSidebar)).width, AppSidebar.iconWidth);
  });

  testWidgets("필터: 품목·거래처로 거르고, 태그·모두 지우기로 풉니다", (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel("품목 필터"));
    await tester.pumpAndSettle();
    expect(find.text("최근 거래순"), findsOneWidget);
    // 선택지 5개 이하: 검색칸 없음.
    expect(find.byType(TextField), findsNothing);
    expect(find.bySemanticsLabel("냉동 딸기, 3건"), findsOneWidget);
    await tester.tap(find.bySemanticsLabel("한라감귤, 2건"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text("확정 거래 2건 · 총 4,190,000원"), findsOneWidget);
    expect(find.bySemanticsLabel("품목 필터, 1개 선택됨"), findsOneWidget);
    expect(find.text("모두 지우기"), findsOneWidget);

    await tester.tap(find.bySemanticsLabel("거래처 필터"));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel("한라푸드, 2건"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("확정 거래 0건 · 총 0원"), findsOneWidget);

    // 태그 ×로 하나 빼기.
    await tester.tap(find.bySemanticsLabel("한라감귤 빼기"));
    await tester.pumpAndSettle();
    expect(find.text("확정 거래 2건 · 총 8,410,000원"), findsOneWidget);

    await tester.tap(find.text("모두 지우기"));
    await tester.pumpAndSettle();
    expect(find.text("확정 거래 5건 · 총 18,000,000원"), findsOneWidget);
    expect(find.text("모두 지우기"), findsNothing);
  });

  testWidgets("정렬: 기본 확정일 최신순, 새 열은 큰 값부터, 다시 누르면 반대", (tester) async {
    await _pump(tester);
    expect(_dates(tester), [
      "2026.10.18",
      "2026.10.10",
      "2026.09.25",
      "2026.09.05",
      "2026.08.28",
    ]);
    expect(_head("확정일"), findsOneWidget);
    expect(find.bySemanticsLabel("확정일, 내림차순 정렬됨"), findsOneWidget);
    expect(find.bySemanticsLabel("단가, 정렬 안 됨"), findsOneWidget);

    await tester.tap(_head("단가"));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel("단가, 내림차순 정렬됨"), findsOneWidget);
    expect(find.bySemanticsLabel("확정일, 정렬 안 됨"), findsOneWidget);
    // 5,400 · 5,000 · 4,900 · 3,900 · 3,700
    expect(_dates(tester), [
      "2026.10.18",
      "2026.10.10",
      "2026.09.05",
      "2026.09.25",
      "2026.08.28",
    ]);

    await tester.tap(_head("단가"));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel("단가, 오름차순 정렬됨"), findsOneWidget);
    expect(_dates(tester), [
      "2026.08.28",
      "2026.09.25",
      "2026.09.05",
      "2026.10.10",
      "2026.10.18",
    ]);

    // 수량: 1,000 · 900 · 800 · 600 · 500
    await tester.tap(_head("수량"));
    await tester.pumpAndSettle();
    expect(_dates(tester), [
      "2026.10.18",
      "2026.09.05",
      "2026.10.10",
      "2026.09.25",
      "2026.08.28",
    ]);

    // 정렬 중인 화살표는 주황, 나머지는 회색 ↕.
    final down = tester.widget<Text>(find.text("↓"));
    expect(down.style!.color, LdsColors.primary);
    final idle = tester.widget<Text>(find.text("↕").first);
    expect(idle.style!.color, const Color(0xFFB1B8C0));
    expect(idle.style!.fontSize, 12);
  });

  testWidgets("같은 값은 날짜 최신순", (tester) async {
    await _pump(
      tester,
      records: [
        _record("1", "2026-10-01", 5000),
        _record("2", "2026-10-05", 5000),
      ],
    );
    await tester.tap(_head("총액"));
    await tester.pumpAndSettle();
    expect(_dates(tester), ["2026.10.05", "2026.10.01"]);
    await tester.tap(_head("총액"));
    await tester.pumpAndSettle();
    expect(_dates(tester), ["2026.10.05", "2026.10.01"]);
  });

  testWidgets("단가 대비: ▲·첫 거래, 단가는 보통 굵기", (tester) async {
    await _pump(tester);
    final up = tester.widget<Text>(find.text("▲ 400원 · +8%"));
    expect(up.style!.color, LdsColors.priceUp);
    expect(up.style!.fontSize, 13);
    expect(find.text("▲ 200원 · +5.4%"), findsOneWidget);
    expect(find.text("▲ 100원 · +2%"), findsOneWidget);
    final first = tester.widget<Text>(find.text("첫 거래").first);
    expect(find.text("첫 거래"), findsNWidgets(2));
    expect(first.style!.color, const Color(0xFF8A95A0));
    expect(find.byTooltip("직전 2026.10.10 한라푸드 5,000원/kg 대비"), findsOneWidget);

    final price = tester.widget<Text>(find.text("5,400원/kg"));
    expect(price.style!.fontWeight, FontWeight.w400);
    expect(price.style!.color, LdsColors.title);
  });

  testWidgets("단가 대비: ▼·직전과 같음", (tester) async {
    await _pump(
      tester,
      records: [
        _record("1", "2026-10-01", 5000),
        _record("2", "2026-10-05", 4900),
        _record("3", "2026-10-09", 4900),
        _record("4", "2026-10-12", 4410),
      ],
    );
    final down = tester.widget<Text>(find.text("▼ 100원 · −2%"));
    expect(down.style!.color, LdsColors.priceDown);
    expect(find.text("▼ 490원 · −10%"), findsOneWidget);
    final same = tester.widget<Text>(find.text("직전과 같음"));
    expect(same.style!.color, const Color(0xFF8A95A0));
    expect(find.byTooltip("직전 2026.10.05 업체2 4,900원/kg 대비"), findsOneWidget);
  });

  testWidgets("빈 상태", (tester) async {
    await _pump(tester, records: const []);
    expect(find.text("확정 거래 0건 · 총 0원"), findsOneWidget);
    final empty = tester.widget<Text>(
      find.text("이 기간·조건에 확정된 거래가 없어요. 기간을 넓히거나 필터를 지워 보세요."),
    );
    expect(empty.style!.color, LdsColors.muted);
  });

  testWidgets("기간 밖 거래는 빠집니다", (tester) async {
    await _pump(
      tester,
      records: [
        _record("1", "2026-08-18", 5000),
        _record("2", "2026-08-19", 5200),
      ],
    );
    expect(find.text("확정 거래 1건 · 총 520,000원"), findsOneWidget);
    // 직전 거래는 기간 밖이어도 비교합니다.
    expect(find.text("▲ 200원 · +4%"), findsOneWidget);
  });

  testWidgets("줄을 누르면 오른쪽 상세 창, 목록은 남습니다", (tester) async {
    await _pump(tester);
    expect(find.byType(TransactionDetailPanel), findsNothing);
    await tester.tap(find.text("바른채소"));
    await tester.pumpAndSettle();

    final panel = find.byType(TransactionDetailPanel);
    expect(panel, findsOneWidget);
    expect(tester.getSize(panel).width, TransactionDetailPanel.width);
    expect(find.text("냉동 딸기 · 바른채소"), findsOneWidget);
    expect(find.text("확정"), findsOneWidget);
    expect(find.text("2026.10.10 · 한라푸드 · 5,000원/kg"), findsOneWidget);
    expect(find.text("Suppliers에서 바른채소 보기"), findsOneWidget);
    expect(find.text("냉동 딸기 확정 단가 흐름"), findsOneWidget);
    // 확정 방식·증빙·업무 연결 칸은 없습니다.
    expect(find.text("근거"), findsNothing);
    expect(find.text("확정 방식"), findsNothing);
    expect(find.text("확정 거래 5건 · 총 18,000,000원"), findsOneWidget);
    // 상세 창은 목록 오른쪽.
    expect(
      tester.getTopLeft(panel).dx,
      greaterThan(tester.getTopLeft(find.text("바른채소").first).dx),
    );

    await tester.tap(find.byTooltip("상세 닫기"));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);

    // Enter로도 고릅니다.
    Focus.of(tester.element(find.text("남도청과").first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text("한라감귤 · 남도청과"), findsOneWidget);

    // Suppliers 링크.
    await tester.tap(find.text("Suppliers에서 남도청과 보기"));
    await tester.pumpAndSettle();
    expect(find.text("page /suppliers"), findsOneWidget);
  });

  testWidgets("1100px 이하: 상세 창이 목록 아래", (tester) async {
    await _pump(tester, width: 1000);
    await tester.tap(find.text("바른채소"));
    await tester.pumpAndSettle();
    final panel = find.byType(TransactionDetailPanel);
    expect(
      tester.getTopLeft(panel).dy,
      greaterThan(tester.getBottomLeft(find.text("바른채소").first).dy),
    );
  });

  testWidgets("기간을 바꾸면 선택이 풀립니다", (tester) async {
    await _pump(tester);
    await tester.tap(find.text("바른채소"));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailPanel), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TransactionsView)),
    );
    tester
        .widget<LdsDateRangeButton>(find.byType(LdsDateRangeButton))
        .onChanged(
          DateTimeRange(
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 30),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailPanel), findsNothing);
    expect(container.read(transactionsPeriodProvider).start.month, 9);
    expect(find.text("확정 거래 2건 · 총 6,750,000원"), findsOneWidget);
  });

  testWidgets("Suppliers에서 넘어오면 안내 띠·필터·선택", (tester) async {
    await _pump(
      tester,
      at: AppPaths.transactionsFor(
        supplierItemId: "sample-item-strawberry-halla",
        itemName: "냉동 딸기",
        date: "2026-10-10",
      ),
    );
    final note = tester.widget<Text>(
      find.text("Suppliers에서 넘어왔어요 · 한라푸드 · 냉동 딸기로 걸러 보는 중"),
    );
    expect(note.style!.color, const Color(0xFFC24A00));
    expect(note.style!.fontSize, 14);
    expect(find.text("확정 거래 2건 · 총 8,410,000원"), findsOneWidget);
    expect(find.text("냉동 딸기 · 한라푸드"), findsOneWidget);
    expect(find.text("2026.09.05 · 한라푸드 · 4,900원/kg"), findsOneWidget);

    // 필터를 바꾸면 안내가 사라집니다.
    await tester.tap(find.text("모두 지우기"));
    await tester.pumpAndSettle();
    expect(find.textContaining("Suppliers에서 넘어왔어요"), findsNothing);
    expect(find.byType(TransactionDetailPanel), findsNothing);
  });

  testWidgets("휴대폰 아래 탭에 Transactions", (tester) async {
    // 시험 글꼴(Ahem)은 글자가 넓어 기간 단추가 길어집니다. 600 미만이면 휴대폰 화면.
    await _pump(tester, width: 560, platform: TargetPlatform.android);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(5));
    expect(
      [
        for (final destination in bar.destinations)
          (destination as NavigationDestination).label,
      ],
      ["Dashboard", "Tasks", "Transactions", "Suppliers", "계정 설정"],
    );
    expect(bar.selectedIndex, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Suppliers '마지막 실거래'는 Transactions 입구", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final router = GoRouter(
      initialLocation: "/suppliers",
      routes: [
        GoRoute(
          path: "/suppliers",
          builder: (_, _) => Scaffold(
            body: SingleChildScrollView(
              child: SupplierItemCard(
                initiallyExpanded: true,
                onOpenEvidence: () {},
                item: const SupplierItem(
                  id: "i1",
                  itemName: "냉동 딸기",
                  certifications: [],
                  lastPurchase: LastPurchase(
                    unitPrice: "5000",
                    unit: "kg",
                    transactionDate: "2026-10-10",
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppPaths.transactions,
          builder: (_, state) => Text("tx ${state.uri.query}"),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text("거래내역 보기 ›"), findsOneWidget);
    await tester.tap(find.text("거래내역 보기 ›"));
    await tester.pumpAndSettle();
    final uri = router.routerDelegate.currentConfiguration.uri;
    expect(uri.path, AppPaths.transactions);
    expect(uri.queryParameters, {
      "supplier_item": "i1",
      "item": "냉동 딸기",
      "date": "2026-10-10",
    });
  });

  testWidgets("필터 창: 결과 없음 문구는 조사를 맞춥니다", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LdsFilterButton(
            label: "거래처",
            options: [for (var i = 0; i < 6; i++) LdsFilterOption("업체$i", 1)],
            selected: const {},
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel("거래처 필터"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "없는 이름");
    await tester.pumpAndSettle();
    expect(find.text("맞는 거래처가 없어요"), findsOneWidget);
  });
}
