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
import "package:gyeonjwo_frontend/features/transactions/presentation/widgets/transaction_list_row.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
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

/// 목록 칸의 거래 줄 안에서만 찾습니다(상세 칸에도 같은 글자가 있어서).
Finder _inRows(Finder finder) =>
    find.descendant(of: find.byType(TransactionListRow), matching: finder);

/// 목록에 보이는 순서(위→아래)대로 확정일.
List<String> _dates(WidgetTester tester) {
  final finder = _inRows(find.textContaining(RegExp(r"^2026\.\d\d\.\d\d · ")));
  final found = finder.evaluate().toList()
    ..sort(
      (a, b) => tester
          .getTopLeft(find.byWidget(a.widget))
          .dy
          .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy),
    );
  return [
    for (final element in found)
      (element.widget as Text).data!.substring(0, 10),
  ];
}

Future<void> _sort(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(RegExp(r"^정렬, ")));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel("$label 정렬"));
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

TransactionListRow _row(WidgetTester tester, int index) => tester
    .widget<TransactionListRow>(find.byType(TransactionListRow).at(index));

void main() {
  testWidgets("기본 기간은 최근 3개월, 목록 위는 건수·총액, 설명 줄 없음", (tester) async {
    await _pump(tester);
    final button = tester.widget<LdsDateRangeButton>(
      find.byType(LdsDateRangeButton),
    );
    expect(button.value.start, DateTime(2026, 8, 19));
    expect(button.value.end, DateTime(2026, 11, 18));
    expect(find.text("2026. 8. 19 - 2026. 11. 18"), findsOneWidget);
    // 기간 선택은 상단 바(높이 64) 안.
    expect(
      tester.getCenter(find.byType(LdsDateRangeButton)).dy,
      lessThan(AppSidebar.headerHeight),
    );
    expect(
      find.text("Thoner에서 확정됐거나 증빙이 등록된 거래를 기간·품목·거래처로 찾아봅니다."),
      findsNothing,
    );
    expect(find.text("확정 거래 5건 · 총 18,000,000원"), findsOneWidget);
    // 7열 표는 없습니다.
    expect(find.byType(LdsListTable), findsNothing);
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

  testWidgets("정렬 선택: 기본 최신순, 선택지 8개, 고르면 그 순서로", (tester) async {
    await _pump(tester);
    expect(_dates(tester), [
      "2026.10.18",
      "2026.10.10",
      "2026.09.25",
      "2026.09.05",
      "2026.08.28",
    ]);
    // 필터 줄 오른쪽 끝.
    final sort = find.bySemanticsLabel("정렬, 최신순");
    expect(sort, findsOneWidget);
    expect(
      tester.getCenter(sort).dy,
      closeTo(tester.getCenter(find.bySemanticsLabel("품목 필터")).dy, 1),
    );
    expect(
      tester.getTopLeft(sort).dx,
      greaterThan(tester.getTopRight(find.bySemanticsLabel("거래처 필터")).dx),
    );

    await tester.tap(sort);
    await tester.pumpAndSettle();
    for (final label in [
      "최신순",
      "오래된순",
      "단가 높은순",
      "단가 낮은순",
      "총액 높은순",
      "총액 낮은순",
      "수량 많은순",
      "수량 적은순",
    ]) {
      expect(find.bySemanticsLabel("$label 정렬"), findsOneWidget);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 5,400 · 5,000 · 4,900 · 3,900 · 3,700
    await _sort(tester, "단가 높은순");
    expect(find.bySemanticsLabel("정렬, 단가 높은순"), findsOneWidget);
    expect(_dates(tester), [
      "2026.10.18",
      "2026.10.10",
      "2026.09.05",
      "2026.09.25",
      "2026.08.28",
    ]);

    await _sort(tester, "단가 낮은순");
    expect(_dates(tester), [
      "2026.08.28",
      "2026.09.25",
      "2026.09.05",
      "2026.10.10",
      "2026.10.18",
    ]);

    // 수량: 1,000 · 900 · 800 · 600 · 500
    await _sort(tester, "수량 많은순");
    expect(_dates(tester), [
      "2026.10.18",
      "2026.09.05",
      "2026.10.10",
      "2026.09.25",
      "2026.08.28",
    ]);

    await _sort(tester, "오래된순");
    expect(_dates(tester), [
      "2026.08.28",
      "2026.09.05",
      "2026.09.25",
      "2026.10.10",
      "2026.10.18",
    ]);
  });

  testWidgets("같은 값은 날짜 최신순", (tester) async {
    await _pump(
      tester,
      records: [
        _record("1", "2026-10-01", 5000),
        _record("2", "2026-10-05", 5000),
      ],
    );
    await _sort(tester, "총액 높은순");
    expect(_dates(tester), ["2026.10.05", "2026.10.01"]);
    await _sort(tester, "총액 낮은순");
    expect(_dates(tester), ["2026.10.05", "2026.10.01"]);
  });

  testWidgets("두 줄 행: 품목·거래처·단가 / 날짜·수량·직전 대비", (tester) async {
    await _pump(tester);
    final first = find.byType(TransactionListRow).first;
    Finder inFirst(String text) =>
        find.descendant(of: first, matching: find.text(text));
    final item = tester.widget<Text>(inFirst("냉동 딸기"));
    expect(item.style!.fontSize, 15);
    expect(item.style!.fontWeight, FontWeight.w700);
    final supplier = tester.widget<Text>(inFirst("바른채소"));
    expect(supplier.style!.fontSize, 13);
    expect(supplier.style!.color, LdsColors.muted);
    final second = tester.widget<Text>(inFirst("2026.10.18 · 1,000kg"));
    expect(second.style!.fontSize, 13);
    expect(second.style!.color, LdsColors.muted);
    // 1줄: 품목 < 거래처 < 단가(오른쪽), 2줄: 날짜·수량 < 직전 대비(오른쪽).
    final top = tester.getCenter(inFirst("냉동 딸기")).dy;
    expect(tester.getCenter(inFirst("5,400원/kg")).dy, closeTo(top, 2));
    expect(
      tester.getTopLeft(inFirst("5,400원/kg")).dx,
      greaterThan(tester.getTopLeft(inFirst("바른채소")).dx),
    );
    final bottom = tester.getCenter(inFirst("2026.10.18 · 1,000kg")).dy;
    expect(bottom, greaterThan(top));
    expect(tester.getCenter(inFirst("▲ 400원 · +8%")).dy, closeTo(bottom, 2));
    // 묶음 상자: 흰 바탕, 1px #E5E7EA, 모서리 12.
    final box = tester.widget<Container>(
      find
          .ancestor(of: first, matching: find.byType(Container))
          .evaluate()
          .map((element) => find.byWidget(element.widget))
          .firstWhere((finder) {
            final widget = tester.widget<Container>(finder);
            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.borderRadius == BorderRadius.circular(12);
          }),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.border, Border.all(color: LdsColors.line));
  });

  testWidgets("단가 대비: ▲·첫 거래, 단가는 보통 굵기", (tester) async {
    await _pump(tester);
    final up = tester.widget<Text>(_inRows(find.text("▲ 400원 · +8%")));
    expect(up.style!.color, LdsColors.priceUp);
    expect(up.style!.fontSize, 13);
    expect(_inRows(find.text("▲ 200원 · +5.4%")), findsOneWidget);
    expect(_inRows(find.text("▲ 100원 · +2%")), findsOneWidget);
    final first = tester.widget<Text>(_inRows(find.text("첫 거래")).first);
    expect(_inRows(find.text("첫 거래")), findsNWidgets(2));
    expect(first.style!.color, const Color(0xFF8A95A0));
    expect(
      _inRows(find.byTooltip("직전 2026.10.10 한라푸드 5,000원/kg 대비")),
      findsOneWidget,
    );

    final price = tester.widget<Text>(_inRows(find.text("5,400원/kg")));
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
    final down = tester.widget<Text>(_inRows(find.text("▼ 100원 · −2%")));
    expect(down.style!.color, LdsColors.priceDown);
    expect(_inRows(find.text("▼ 490원 · −10%")), findsOneWidget);
    final same = tester.widget<Text>(_inRows(find.text("직전과 같음")));
    expect(same.style!.color, const Color(0xFF8A95A0));
    expect(
      _inRows(find.byTooltip("직전 2026.10.05 업체2 4,900원/kg 대비")),
      findsOneWidget,
    );
  });

  testWidgets("빈 상태: 목록 칸에 문구, 상세 칸은 비움", (tester) async {
    await _pump(tester, records: const []);
    expect(find.text("확정 거래 0건 · 총 0원"), findsOneWidget);
    final empty = find.text("이 기간·조건에 확정된 거래가 없어요. 기간을 넓히거나 필터를 지워 보세요.");
    expect(tester.widget<Text>(empty).style!.color, LdsColors.muted);
    expect(find.descendant(of: _listPane, matching: empty), findsOneWidget);
    expect(find.byType(TransactionDetailPanel), findsNothing);
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
    expect(_inRows(find.text("▲ 200원 · +4%")), findsOneWidget);
  });

  testWidgets("넓은 화면: 목록 칸 30% + 상세 칸, 첫 거래를 골라 엽니다", (tester) async {
    await _pump(tester);
    // 목록 칸: 폭 = 목록 30%(400~480) + 왼쪽 24 + 오른쪽 16 + 선 1,
    // #F3F4F6 + 오른쪽 1px 선. 상세 칸 #F9FAFB.
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

    // 첫 거래가 골라져 있습니다: #FFF4EC + 왼쪽 주황 3px.
    expect(_row(tester, 0).selected, isTrue);
    expect(_row(tester, 1).selected, isFalse);
    final first = find.byType(TransactionListRow).first;
    expect(
      tester
          .widget<Material>(
            find.descendant(of: first, matching: find.byType(Material)).first,
          )
          .color,
      LdsColors.selectedRow,
    );
    final bar = find.descendant(
      of: first,
      matching: find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == LdsColors.primary,
      ),
    );
    expect(tester.getSize(bar).width, 3);

    final panel = find.byType(TransactionDetailPanel);
    expect(panel, findsOneWidget);
    expect(find.text("냉동 딸기 · 바른채소"), findsOneWidget);
    expect(find.text("확정"), findsOneWidget);
    expect(find.text("확정 정보"), findsOneWidget);
    expect(find.text("2026.10.10 · 한라푸드 · 5,000원/kg"), findsOneWidget);
    expect(find.text("Suppliers에서 바른채소 보기"), findsOneWidget);
    expect(find.text("냉동 딸기 확정 단가 흐름"), findsOneWidget);
    // 넓은 화면은 늘 고른 거래를 보여 주므로 닫기 단추가 없습니다.
    expect(find.byTooltip("상세 닫기"), findsNothing);
    // 확정 방식·증빙·업무 연결 칸은 없습니다.
    expect(find.text("근거"), findsNothing);
    expect(find.text("확정 방식"), findsNothing);
    // 상세는 목록 칸 오른쪽, 상세 칸 위 24에서 시작.
    expect(
      tester.getTopLeft(panel).dx,
      greaterThan(tester.getTopRight(_listPane).dx),
    );

    // 다른 줄을 누르면 그 거래.
    await tester.tap(_inRows(find.text("남도청과")).first);
    await tester.pumpAndSettle();
    expect(find.text("한라감귤 · 남도청과"), findsOneWidget);
    expect(_row(tester, 2).selected, isTrue);
    expect(find.text("확정 거래 5건 · 총 18,000,000원"), findsOneWidget);

    // Enter로도 고릅니다.
    Focus.of(tester.element(_inRows(find.text("한라푸드")).first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text("냉동 딸기 · 한라푸드"), findsOneWidget);

    // Suppliers 링크.
    await tester.tap(find.text("Suppliers에서 한라푸드 보기"));
    await tester.pumpAndSettle();
    expect(find.text("page /suppliers"), findsOneWidget);
  });

  testWidgets("↑/↓로 이전·다음 거래를 엽니다", (tester) async {
    await _pump(tester);
    await tester.tap(_inRows(find.text("바른채소")));
    await tester.pumpAndSettle();
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    await press(LogicalKeyboardKey.arrowDown);
    expect(_row(tester, 1).selected, isTrue);
    expect(find.text("냉동 딸기 · 한라푸드"), findsOneWidget);
    await press(LogicalKeyboardKey.arrowDown);
    expect(find.text("한라감귤 · 남도청과"), findsOneWidget);
    await press(LogicalKeyboardKey.arrowUp);
    await press(LogicalKeyboardKey.arrowUp);
    expect(_row(tester, 0).selected, isTrue);
    // 첫 줄 위로는 가지 않습니다.
    await press(LogicalKeyboardKey.arrowUp);
    expect(_row(tester, 0).selected, isTrue);
  });

  testWidgets("1100px 이하: 목록과 상세를 한 화면씩", (tester) async {
    await _pump(tester, width: 1000);
    // 목록만, 자동으로 열지 않습니다.
    expect(find.byType(TransactionListRow), findsNWidgets(5));
    expect(find.byType(TransactionDetailPanel), findsNothing);
    expect(_listPane, findsNothing);

    await tester.tap(_inRows(find.text("바른채소")));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailPanel), findsOneWidget);
    expect(find.byType(TransactionListRow), findsNothing);
    expect(find.text("냉동 딸기 · 바른채소"), findsOneWidget);

    await tester.tap(find.text("목록으로"));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailPanel), findsNothing);
    expect(find.byType(TransactionListRow), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets("기간을 바꾸면 새 기간의 첫 거래를 엽니다", (tester) async {
    await _pump(tester);
    expect(find.text("냉동 딸기 · 바른채소"), findsOneWidget);
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
    expect(container.read(transactionsPeriodProvider).start.month, 9);
    expect(find.text("확정 거래 2건 · 총 6,750,000원"), findsOneWidget);
    expect(find.text("냉동 딸기 · 바른채소"), findsNothing);
    expect(find.text("한라감귤 · 남도청과"), findsOneWidget);
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
    final noteFinder = find.text("Suppliers에서 넘어왔어요 · 한라푸드 · 냉동 딸기로 걸러 보는 중");
    final note = tester.widget<Text>(noteFinder);
    expect(note.style!.color, const Color(0xFFC24A00));
    expect(note.style!.fontSize, 14);
    // 안내 띠는 목록 칸 맨 위(필터 줄 위).
    expect(
      find.descendant(of: _listPane, matching: noteFinder),
      findsOneWidget,
    );
    expect(
      tester.getBottomLeft(noteFinder).dy,
      lessThan(tester.getTopLeft(find.bySemanticsLabel(RegExp("^품목 필터"))).dy),
    );
    expect(find.text("확정 거래 2건 · 총 8,410,000원"), findsOneWidget);
    // 넘어온 거래가 골라져 있습니다(첫 줄 자동 선택이 덮지 않음).
    expect(find.text("냉동 딸기 · 한라푸드"), findsOneWidget);
    expect(find.text("2026.09.05 · 한라푸드 · 4,900원/kg"), findsOneWidget);
    expect(_row(tester, 0).selected, isTrue);

    // 필터를 바꾸면 안내가 사라지고 첫 거래를 엽니다.
    await tester.tap(find.text("모두 지우기"));
    await tester.pumpAndSettle();
    expect(find.textContaining("Suppliers에서 넘어왔어요"), findsNothing);
    expect(find.text("냉동 딸기 · 바른채소"), findsOneWidget);
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
