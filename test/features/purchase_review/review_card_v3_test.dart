import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/plan_board.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/plan_card.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/review_card_content.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

PlanAllocation _alloc(String id, String name, String quantity, String price) =>
    PlanAllocation(
      supplierId: id,
      supplierName: name,
      quoteId: "q-$id",
      quantity: quantity,
      unit: "kg",
      unitPrice: price,
    );

ReviewCard _card({List<ResponsePlan>? plans}) => ReviewCard(
  caseId: "c1",
  reviewRevision: 1,
  inputRevision: 2,
  isStale: false,
  outcome: ReviewOutcome.completed,
  plans:
      plans ??
      [
        ResponsePlan(
          planId: "p-KEEP",
          planType: "KEEP",
          validationStatus: "CONDITIONAL",
          totalAmount: "5800000",
          allocations: [_alloc("halla", "한라푸드", "1000", "5800")],
          reason: "지금 거래 중인 업체를 그대로 유지하는 기준안입니다.",
          conditions: const ["역제안 회신에 따라 단가가 바뀔 수 있습니다."],
        ),
        ResponsePlan(
          planId: "p-SWITCH",
          planType: "SWITCH",
          validationStatus: "VALID",
          totalAmount: "5400000",
          allocations: [_alloc("baren", "바른채소", "1000", "5400")],
          reason: "한 업체로 전량 바꾸는 안입니다.",
        ),
        ResponsePlan(
          planId: "p-SPLIT",
          planType: "SPLIT",
          validationStatus: "VALID",
          totalAmount: "5560000",
          allocations: [
            _alloc("baren", "바른채소", "600", "5400"),
            _alloc("halla", "한라푸드", "400", "5800"),
          ],
          reason: "두 업체에 나눠 사는 안입니다.",
        ),
      ],
  questions: const [
    ReviewQuestion(
      supplierName: "남도청과",
      field: "shipping_cost",
      priority: "HIGH",
      reason: "운송비가 메일에 없어 총액을 비교하지 못했습니다.",
      breakEvenAmount: "100000",
    ),
  ],
  allowedActions: const ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
);

QuoteVersion _quote(
  String id,
  String name,
  String price, {
  bool incumbent = false,
}) => QuoteVersion(
  quoteId: "q-$id",
  versionNo: 1,
  supplierId: id,
  supplierName: name,
  isIncumbent: incumbent,
  extractionStatus: "STORED",
  unitPrice: price,
  unit: "kg",
  taxBasis: "EXCLUDED",
  evidence: [
    QuoteEvidence(
      field: "unit_price",
      mailId: "m-$id",
      rawValue: price,
      location: "body",
    ),
  ],
);

final _quotes = [
  _quote("halla", "한라푸드", "5800", incumbent: true),
  _quote("baren", "바른채소", "5400"),
  _quote("namdo", "남도청과", "5300"),
];

Future<void> _pump(WidgetTester tester, {double width = 1440}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = Size(width, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(WorkspacePalette.lds),
        home: Scaffold(
          body: ReviewCardContent(
            review: PurchaseReview(card: _card(), quotes: _quotes),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _plan(String type) =>
    find.ancestor(of: find.text(type), matching: find.byType(PlanCard));

void main() {
  testWidgets("three cards side by side, same height, rows aligned", (
    tester,
  ) async {
    await _pump(tester);
    final cards = [
      for (final type in ["기존 업체 유지", "전량 전환", "분산 구매"])
        tester.getRect(_plan(type)),
    ];
    // Server order, one row, same width and height.
    expect(cards[0].right, lessThan(cards[1].left));
    expect(cards[1].right, lessThan(cards[2].left));
    for (final card in cards.skip(1)) {
      expect(card.top, cards[0].top);
      expect(card.height, cards[0].height);
      expect(card.width, closeTo(cards[0].width, 1));
    }
    // The totals sit on the same line in every card.
    final totals = [
      for (final total in ["5,800,000 원", "5,400,000 원", "5,560,000 원"])
        tester.getRect(find.text(total, findRichText: true)).top,
    ];
    expect(totals[1], closeTo(totals[0], 1));
    expect(totals[2], closeTo(totals[0], 1));
    // So do the allocations, at the bottom.
    final bars = tester
        .widgetList<LdsRatioBar>(find.byType(LdsRatioBar))
        .toList();
    expect(bars, hasLength(3));
    final barTops = [
      for (final bar in find.byType(LdsRatioBar).evaluate())
        tester.getTopLeft(find.byWidget(bar.widget)).dy,
    ];
    expect(barTops[1], closeTo(barTops[0], 1));
    expect(barTops[2], closeTo(barTops[0], 1));
  });

  testWidgets("the lowest plan: orange 2px, '최저 총액', a filled button", (
    tester,
  ) async {
    await _pump(tester);
    final lowest = tester.widget<Container>(
      find
          .descendant(of: _plan("전량 전환"), matching: find.byType(Container))
          .first,
    );
    final border = (lowest.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, LdsColors.primary);
    expect(border.top.width, 2);
    expect(
      find.descendant(of: _plan("전량 전환"), matching: find.text("최저 총액")),
      findsOneWidget,
    );
    expect(find.text("가장 낮음"), findsOneWidget);
    expect(find.text("+160,000원"), findsOneWidget);
    // One filled button (the lowest), one outlined, the conditional one
    // has a dashed box with the reason.
    expect(find.widgetWithText(FilledButton, "선택"), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, "선택"), findsOneWidget);
    expect(find.text("선택 불가 · 조건부 안은 아직 확정할 수 없습니다."), findsOneWidget);
    expect(tester.getSize(find.widgetWithText(FilledButton, "선택")).height, 44);
    // No dark cards any more: white, or light grey when it cannot be
    // confirmed.
    Color? fill(String type) =>
        (tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: _plan(type),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration)
            .color;
    expect(fill("전량 전환"), Colors.white);
    expect(fill("분산 구매"), Colors.white);
    expect(fill("기존 업체 유지"), LdsColors.canvas);
  });

  testWidgets("one supplier keeps one colour across the cards and the table", (
    tester,
  ) async {
    await _pump(tester);
    List<Color> colorsIn(String type) => [
      for (final segment
          in tester
              .widget<LdsRatioBar>(
                find.descendant(
                  of: _plan(type),
                  matching: find.byType(LdsRatioBar),
                ),
              )
              .segments)
        segment.color,
    ];
    // 바른채소 is in the lowest plan: orange; 한라푸드 next: ink.
    expect(colorsIn("전량 전환"), [LdsColors.primary]);
    expect(colorsIn("기존 업체 유지"), [LdsColors.title]);
    expect(colorsIn("분산 구매"), [LdsColors.primary, LdsColors.title]);
    final table = tester.widget<LdsCompareTable>(find.byType(LdsCompareTable));
    expect(table.options.map((option) => option.marker), [
      LdsColors.title,
      LdsColors.primary,
      // Not in any plan: grey.
      LdsColors.disabled,
    ]);
  });

  testWidgets("quotes and evidence is a compare table, 150 label column", (
    tester,
  ) async {
    await _pump(tester);
    final table = tester.widget<LdsCompareTable>(find.byType(LdsCompareTable));
    expect(table.labelWidth, 150);
    expect(table.options.map((option) => option.title), [
      "한라푸드",
      "바른채소",
      "남도청과",
    ]);
    expect(table.options.first.caption, "기존 거래처");
    expect(table.rows.map((row) => row.label).take(5), [
      "단가",
      "부가세",
      "공급 가능량",
      "최소 주문",
      "적용일",
    ]);
    // Evidence buttons are at least 24 tall and name what they open.
    final evidence = find.bySemanticsLabel(RegExp("단가 근거 원문 보기"));
    expect(evidence, findsNWidgets(3));
    expect(tester.getSize(evidence.first).height, greaterThanOrEqualTo(24));
  });

  testWidgets("sections in order, 40 apart; the strip names what to check", (
    tester,
  ) async {
    await _pump(tester);
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    expect(top("구매안 비교"), lessThan(top("확인할 항목")));
    expect(top("확인할 항목"), lessThan(top("견적과 근거")));
    expect(find.text("확인할 항목 보기"), findsOneWidget);
    expect(
      find.descendant(
        of: find
            .ancestor(of: find.text("확인할 항목"), matching: find.byType(Row))
            .first,
        matching: find.byType(LdsBadge),
      ),
      findsOneWidget,
    );
  });

  testWidgets("under 900 wide: one card per row", (tester) async {
    await _pump(tester, width: 880);
    final keep = tester.getRect(_plan("기존 업체 유지"));
    final change = tester.getRect(_plan("전량 전환"));
    expect(change.top, greaterThan(keep.bottom));
    expect(change.left, keep.left);
    expect(tester.takeException(), isNull);
  });

  test("lowest plan: the cheapest one that can be confirmed", () {
    final plans = _card().plans;
    expect(PlanBoard.lowestPlan(plans)?.planType, "SWITCH");
  });
}
