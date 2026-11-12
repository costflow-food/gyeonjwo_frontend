import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/unresolved_line.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/counter_offer_panel.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/review_card_content.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

const _supplier = "8a41d7b2-1c3e-4f6a-b0d5-93e2c7a6f540";
const _mail = "19c0f3a2-b7d4-4e21-9a55-0c1d2e3f4a5b";
const _reason =
    "기존 업체와 대안 업체의 세금 기준이 달라 가격을 같은 기준으로 비교할 수 없어 "
    "목표 단가를 정하거나 역제안 초안을 만들 수 없습니다. 세금 기준을 확인한 뒤 다시 검토해야 합니다.";

ReviewCard _card({
  List<String> unresolved = const ["COUNTER_OFFER HOLD: $_reason"],
  CounterOffer? offer = const CounterOffer(status: "HOLD", reason: _reason),
  ReviewOutcome outcome = ReviewOutcome.reviewRequiredClosed,
  bool stale = false,
  int plans = 2,
}) => ReviewCard(
  caseId: "c1",
  reviewRevision: 1,
  inputRevision: 1,
  isStale: stale,
  outcome: outcome,
  createdAt: "2026-11-11T08:20:00Z",
  plans: [
    for (final type in ["KEEP", "SWITCH"].take(plans))
      ResponsePlan(
        planId: "p-$type",
        planType: type,
        validationStatus: "VALID",
        totalAmount: "2750000",
        allocations: const [
          PlanAllocation(
            supplierId: _supplier,
            supplierName: "새벽딸기",
            quoteId: "q1",
            quantity: "500",
            unit: "kg",
            unitPrice: "5500",
          ),
        ],
      ),
  ],
  counterOffer: offer,
  unresolved: unresolved,
  allowedActions: const ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
);

List<(String?, String, bool)> _lines(
  ReviewCard card, {
  List<QuoteVersion> quotes = const [],
}) => [
  for (final line in unresolvedLines(card, quotes: quotes))
    (line.label, line.text, line.inCounterOffer),
];

QuoteVersion _quote(String supplierId, String name) => QuoteVersion(
  quoteId: "q-$supplierId",
  versionNo: 1,
  supplierId: supplierId,
  supplierName: name,
  isIncumbent: false,
  extractionStatus: "STORED",
);

Future<void> _pump(
  WidgetTester tester,
  ReviewCard card, {
  Size size = const Size(360, 760),
  double textScale = 1,
  List<QuoteVersion> quotes = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final content = ReviewCardContent(
    review: PurchaseReview(card: card, quotes: quotes),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        // A phone gets the card's own screen; wider, the card sits in a
        // scrolling page as it does on the web.
        home: size.width < 600
            ? content
            : Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inPanel(Finder matching) =>
    find.descendant(of: find.byType(CounterOfferPanel), matching: matching);

void main() {
  group("unresolvedLines", () {
    test("a held counter-offer whose reason the panel shows is only named", () {
      expect(_lines(_card()), [("역제안 보류", "", true)]);
    });

    test("a hold reason the panel does not show stays in the notice", () {
      expect(_lines(_card(offer: null)), [("역제안 보류", _reason, false)]);
      expect(
        _lines(
          _card(
            offer: const CounterOffer(status: "HOLD", reason: "다른 사유"),
          ),
        ),
        [("역제안 보류", _reason, false)],
      );
      expect(
        _lines(
          _card(
            offer: const CounterOffer(status: "PROPOSED", reason: _reason),
          ),
        ),
        [("역제안 보류", _reason, false)],
      );
      expect(
        _lines(_card(unresolved: ["INFO_EXTRACTOR HOLD: 단가를 읽지 못했습니다."])),
        [("견적 읽기 보류", "단가를 읽지 못했습니다.", false)],
      );
    });

    test("field and cost names are gathered per supplier in Korean", () {
      expect(
        _lines(
          _card(
            unresolved: [
              "$_supplier.cost:SHIPPING",
              "tax_terms",
              "$_supplier.tax_terms",
              "moq",
              "$_supplier.cost:SHIPPING",
            ],
          ),
        ),
        [("새벽딸기", "운송비, 부가세 미확인", false), (null, "부가세, 최소 주문 수량 미확인", false)],
      );
    });

    test("a supplier is named from the quotes, whatever the letter case", () {
      const other = "0f3c9a11-7b2d-4c58-9e60-1a2b3c4d5e6f";
      expect(
        _lines(
          _card(unresolved: ["${other.toUpperCase()}.tax_terms"]),
          quotes: [_quote(other, "산들청과")],
        ),
        [("산들청과", "부가세 미확인", false)],
      );
      // The quote's name wins over the name a plan carries.
      expect(
        _lines(
          _card(unresolved: ["$_supplier.unit"]),
          quotes: [_quote(_supplier, "새벽딸기 농업회사법인")],
        ),
        [("새벽딸기 농업회사법인", "단위 미확인", false)],
      );
    });

    test("a supplier the card does not name is not taken for the request", () {
      const stranger = "0f3c9a11-7b2d-4c58-9e60-1a2b3c4d5e6f";
      expect(
        _lines(
          _card(
            unresolved: [
              "S1.unit_price",
              "unit_price",
              "S2.unit_price",
              "$stranger.lead_time",
              "삼성식품.unit_price",
              "S1.운송비",
              "$_supplier.하차비",
            ],
          ),
        ),
        [
          ("업체 미확인", "단가, 납기 소요기간, 운송비 미확인", false),
          (null, "단가 미확인", false),
          ("삼성식품", "단가 미확인", false),
          ("새벽딸기", "하차비 미확인", false),
        ],
      );
    });

    test("an attachment that could not be read shows its file name", () {
      expect(
        _lines(
          _card(
            unresolved: [
              "$_mail 견적서_스캔.pdf: 글자가 없는 PDF(스캔본)라 읽지 못했습니다",
              "$_mail 11월: 단가표.xlsx: 첨부가 너무 커서 읽지 않았습니다",
              "$_mail None: 첨부를 읽는 중 오류가 났습니다",
            ],
          ),
        ),
        [
          ("견적서_스캔.pdf", "글자가 없는 PDF(스캔본)라 읽지 못했습니다", false),
          ("11월: 단가표.xlsx", "첨부가 너무 커서 읽지 않았습니다", false),
          ("첨부 파일", "첨부를 읽는 중 오류가 났습니다", false),
        ],
      );
    });

    test("the same file name from another mail is counted, not dropped", () {
      const second = "7d2e4b90-3c1a-4f6e-8b22-5a6b7c8d9e0f";
      expect(
        _lines(
          _card(
            unresolved: [
              "$_mail 견적서.hwp: 첨부가 너무 커서 읽지 않았습니다",
              "$_mail None: 첨부를 받아오지 못했습니다",
              "$second 견적서.hwp: 첨부가 너무 커서 읽지 않았습니다",
              "$second None: 첨부를 받아오지 못했습니다",
              "$second 견적서.hwp: 첨부를 받아오지 못했습니다",
            ],
          ),
        ),
        [
          ("견적서.hwp 2건", "첨부가 너무 커서 읽지 않았습니다", false),
          ("첨부 파일 2건", "첨부를 받아오지 못했습니다", false),
          ("견적서.hwp", "첨부를 받아오지 못했습니다", false),
        ],
      );
    });

    test("sentences stay; codes this app cannot name are only counted", () {
      const sentence = "견적 단가를 읽을 수 없는 회신이 있어 그 회신은 비교에서 뺐습니다.";
      expect(
        _lines(
          _card(
            unresolved: [
              sentence,
              "some_new_token",
              "INPUT_REVISION_CHANGED",
              "$_supplier.cost:NEW_KIND",
              " ",
              sentence,
            ],
          ),
        ),
        [(null, sentence, false), (null, "그 밖에 확인하지 못한 항목 3건", false)],
      );
    });
  });

  group("review card notice", () {
    final longCard = _card(
      unresolved: [
        "$_mail 견적서_스캔.pdf: 글자가 없는 PDF(스캔본)라 읽지 못했습니다",
        "$_mail 단가표.hwp: 지원하지 않는 첨부 형식(.hwp)입니다. PDF·xlsx·jpg·png로 받아야 읽을 수 있습니다",
        "$_supplier.cost:SHIPPING",
        "COUNTER_OFFER HOLD: $_reason",
      ],
    );

    for (final (name, size) in [
      ("phone", const Size(360, 760)),
      ("web", const Size(1280, 900)),
    ]) {
      testWidgets("$name: a held counter-offer is named once, in caution", (
        tester,
      ) async {
        await _pump(tester, _card(), size: size);
        expect(find.text("확인할 것이 남은 채 검토를 마쳤습니다."), findsOneWidget);
        expect(find.textContaining("COUNTER_OFFER"), findsNothing);
        expect(find.textContaining("HOLD"), findsNothing);
        // The reason is written once, in the counter-offer panel.
        expect(
          find.textContaining(_reason, findRichText: true),
          findsOneWidget,
        );
        expect(_inPanel(find.text(_reason)), findsOneWidget);
        expect(find.text("사유 보기"), findsOneWidget);
        expect(
          tester.getSemantics(find.text("사유 보기")),
          matchesSemantics(
            label: "역제안 보류\n사유 보기",
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        expect(
          tester
              .widget<Icon>(find.byIcon(Icons.pause_circle_outline).first)
              .color,
          caution,
        );
        // Nothing to propose: no empty range box, no draft button.
        expect(_inPanel(find.text("제안 가능 범위")), findsNothing);
        expect(_inPanel(find.text("메일 초안")), findsNothing);
        expect(
          _inPanel(
            find.textContaining("구매안은 그대로 고를 수 있습니다", findRichText: true),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final scale in [1.0, 1.3]) {
      testWidgets("phone: 사유 보기 scrolls to the reason at scale $scale", (
        tester,
      ) async {
        await _pump(tester, longCard, textScale: scale);
        expect(find.textContaining("견적서_스캔.pdf"), findsOneWidget);
        expect(
          find.textContaining("운송비 미확인", findRichText: true),
          findsOneWidget,
        );
        final reason = find.text(_reason);
        // Below the fold until asked for.
        expect(tester.getRect(reason).top, greaterThan(640));
        await tester.tap(find.text("사유 보기"));
        await tester.pumpAndSettle();
        final shown = tester.getRect(reason);
        expect(shown.top, greaterThan(56));
        expect(shown.bottom, lessThan(690));
        expect(reason.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets("phone: a panel taller than the screen opens at its top", (
      tester,
    ) async {
      final long = "세금 기준을 확인한 뒤 다시 검토해야 합니다. " * 20;
      await _pump(
        tester,
        _card(
          unresolved: ["COUNTER_OFFER HOLD: $long"],
          offer: CounterOffer(status: "HOLD", reason: long),
        ),
        textScale: 1.3,
      );
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey("review-card-scroll")),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final panel = find.byType(CounterOfferPanel);
      expect(
        tester.getSize(panel).height,
        greaterThan(scroll.position.viewportDimension),
      );
      await tester.tap(find.text("사유 보기"));
      // One way down: it never passes the place it stops at.
      var last = scroll.position.pixels;
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(scroll.position.pixels, greaterThanOrEqualTo(last));
        last = scroll.position.pixels;
      }
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, last);
      expect(last, greaterThan(0));
      // The heading and the start of the reason are on screen.
      expect(_inPanel(find.text("역제안")).hitTestable(), findsOneWidget);
      expect(tester.getRect(panel).top, inInclusiveRange(56, 120));
    });

    testWidgets("web, one column: 사유 보기 scrolls to the reason", (tester) async {
      await _pump(tester, _card(), size: const Size(800, 600));
      final reason = find.text(_reason);
      expect(tester.getRect(reason).top, greaterThan(600));
      await tester.tap(find.text("사유 보기"));
      await tester.pumpAndSettle();
      expect(tester.getRect(reason).bottom, lessThan(600));
      expect(reason.hitTestable(), findsOneWidget);
    });

    testWidgets("web, two columns: the panel in view is marked, not moved", (
      tester,
    ) async {
      await _pump(tester, _card(), size: const Size(1280, 900));
      final reason = find.text(_reason);
      final before = tester.getRect(reason);
      double mark() =>
          (tester
                      .widget<AnimatedContainer>(
                        find.ancestor(
                          of: find.byType(CounterOfferPanel),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .boxShadow!
              .single
              .color
              .a;
      expect(mark(), 0);
      await tester.tap(find.text("사유 보기"));
      await tester.pumpAndSettle();
      expect(tester.getRect(reason), before);
      expect(mark(), greaterThan(0));
      // The mark fades by itself.
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(mark(), 0);
    });

    testWidgets("supplier names in the notice come from the quotes", (
      tester,
    ) async {
      const other = "0f3c9a11-7b2d-4c58-9e60-1a2b3c4d5e6f";
      await _pump(
        tester,
        _card(unresolved: ["$other.cost:SHIPPING"], offer: null),
        quotes: [_quote(other, "산들청과")],
      );
      expect(
        find.textContaining("산들청과 · 운송비 미확인", findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining(other, findRichText: true), findsNothing);
    });

    testWidgets("a proposed counter-offer keeps its range and draft button", (
      tester,
    ) async {
      await _pump(
        tester,
        _card(
          unresolved: const [],
          outcome: ReviewOutcome.completed,
          offer: const CounterOffer(
            status: "PROPOSED",
            reason: "대안 총액이 인상안보다 낮습니다.",
            target: CounterOfferTarget(
              supplierId: _supplier,
              supplierName: "새벽딸기",
              targetUnitPrice: "5200",
            ),
            reference: CounterOfferReference(
              status: "OK",
              unit: "kg",
              allowedRange: ["5100", "5300"],
            ),
          ),
        ),
        size: const Size(1280, 900),
      );
      expect(find.byIcon(Icons.pause_circle_outline), findsNothing);
      expect(_inPanel(find.text("역제안 제안")), findsOneWidget);
      expect(_inPanel(find.text("제안 가능 범위")), findsOneWidget);
      expect(_inPanel(find.text("메일 초안")), findsOneWidget);
      expect(_inPanel(find.text("대안 총액이 인상안보다 낮습니다.")), findsOneWidget);
    });

    testWidgets("a held counter-offer with a draft still opens it", (
      tester,
    ) async {
      await _pump(
        tester,
        _card(
          offer: const CounterOffer(
            status: "HOLD",
            reason: _reason,
            draftIds: ["d1"],
          ),
          stale: true,
        ),
      );
      expect(_inPanel(find.text("메일 초안")), findsOneWidget);
      expect(_inPanel(find.text("제안 가능 범위")), findsNothing);
      // An outdated card cannot be chosen from, so it does not say it can.
      expect(
        find.textContaining("구매안은 그대로 고를 수 있습니다", findRichText: true),
        findsNothing,
      );
    });

    testWidgets(
      "a held counter-offer with only an alternative total names it",
      (tester) async {
        await _pump(
          tester,
          _card(
            offer: const CounterOffer(
              status: "HOLD",
              reason: _reason,
              reference: CounterOfferReference(
                status: "OK",
                alternativeTotal: "2502000",
              ),
            ),
          ),
          size: const Size(1280, 900),
        );
        expect(_inPanel(find.text("대안 총액")), findsOneWidget);
        expect(_inPanel(find.text("2,502,000원")), findsOneWidget);
        expect(_inPanel(find.text("제안 가능 범위")), findsNothing);
        expect(_inPanel(find.text("메일 초안")), findsNothing);
        expect(
          _inPanel(
            find.textContaining("목표 단가와 제안 범위는 정해지지", findRichText: true),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets("no plan at all is a stop; something to check is a caution", (
      tester,
    ) async {
      Color? tone() => tester
          .widget<Icon>(find.byIcon(Icons.pause_circle_outline).first)
          .color;
      await _pump(
        tester,
        _card(
          unresolved: const ["tax_terms"],
          offer: null,
          outcome: ReviewOutcome.noValidPlan,
          plans: 0,
        ),
      );
      expect(tone(), danger);
      expect(
        find.textContaining("부가세 미확인", findRichText: true),
        findsOneWidget,
      );
      await _pump(
        tester,
        _card(
          unresolved: const ["tax_terms"],
          offer: null,
          outcome: ReviewOutcome.needsInfo,
        ),
      );
      expect(tone(), caution);
      // Leftovers on a finished comparison are plain information.
      await _pump(
        tester,
        _card(
          unresolved: const ["tax_terms"],
          offer: null,
          outcome: ReviewOutcome.completed,
        ),
      );
      expect(tone(), WorkspacePalette.houseGreen.ink);
      // No leftovers, comparison finished: no notice at all.
      await _pump(
        tester,
        _card(
          unresolved: const [" "],
          offer: null,
          outcome: ReviewOutcome.completed,
        ),
      );
      expect(find.byIcon(Icons.pause_circle_outline), findsNothing);
      // An outdated card is a stop.
      await _pump(
        tester,
        _card(
          unresolved: const [],
          offer: null,
          outcome: ReviewOutcome.completed,
          stale: true,
        ),
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.history)).color, danger);
    });
  });

  group("phone plan list", () {
    ResponsePlan plan(String type, String? total, {String status = "VALID"}) =>
        ResponsePlan(
          planId: "p-$type",
          planType: type,
          validationStatus: status,
          totalAmount: total,
          allocations: const [],
        );
    ReviewCard card(List<ResponsePlan> plans, {String? chosen}) => ReviewCard(
      caseId: "c1",
      reviewRevision: 1,
      inputRevision: 1,
      isStale: false,
      outcome: ReviewOutcome.completed,
      plans: plans,
      decision: chosen == null
          ? null
          : ReviewDecision(decision: ReviewAction.selectPlan, planId: chosen),
      allowedActions: const ["SELECT_PLAN"],
    );
    double top(WidgetTester tester, String text) =>
        tester.getRect(find.text(text)).top;

    testWidgets("plans keep the server's order; the chosen plan is open", (
      tester,
    ) async {
      await _pump(
        tester,
        card([
          plan("KEEP", "2559000"),
          plan("SPLIT", null, status: "NEEDS_INFO"),
          plan("SWITCH", "2502000"),
        ], chosen: "p-KEEP"),
      );
      expect(top(tester, "기존 업체 유지"), lessThan(top(tester, "분산 구매")));
      expect(top(tester, "분산 구매"), lessThan(top(tester, "전량 전환")));
      expect(find.text("미확인"), findsOneWidget);
      expect(find.text("+57,000"), findsOneWidget);
      expect(find.text("최저"), findsOneWidget);
      // Open on the chosen plan, not the lowest.
      expect(find.text("선택한 구매안"), findsOneWidget);
      expect(find.text("이 안 선택"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("starts on the first plan that can be chosen", (tester) async {
      await _pump(
        tester,
        card([
          plan("SWITCH", "2400000", status: "CONDITIONAL"),
          plan("KEEP", "2559000"),
        ]),
      );
      expect(find.text("이 안 선택"), findsOneWidget);
      expect(find.text("수용하기"), findsNothing);
    });

    testWidgets("the open plan stays open over a reload, also without ids", (
      tester,
    ) async {
      ResponsePlan bare(String type, String total) => ResponsePlan(
        planId: null,
        planType: type,
        validationStatus: "CONDITIONAL",
        totalAmount: total,
        allocations: const [],
        reason: "$type 사유",
      );
      List<ResponsePlan> plans() => [
        bare("KEEP", "2559000"),
        bare("SWITCH", "2502000"),
      ];
      await _pump(tester, card(plans()));
      expect(find.text("KEEP 사유"), findsOneWidget);
      await tester.tap(find.text("전량 전환"));
      await tester.pumpAndSettle();
      expect(find.text("SWITCH 사유"), findsOneWidget);
      // The same card again, as new objects.
      await _pump(tester, card(plans()));
      expect(find.text("SWITCH 사유"), findsOneWidget);
      expect(find.text("KEEP 사유"), findsNothing);
      // A new review without the open plan: back to the starting choice.
      await _pump(tester, card([plan("SPLIT", "2600000")]));
      expect(find.text("이 안 선택"), findsOneWidget);
    });

    testWidgets("a long total leaves the name readable at text scale 2", (
      tester,
    ) async {
      await _pump(
        tester,
        card([plan("KEEP", "1255900000"), plan("SWITCH", "1250200000")]),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text("기존 업체 유지")).width, greaterThan(90));
    });

    testWidgets("a single plan is simply open", (tester) async {
      await _pump(tester, card([plan("KEEP", "2559000")]));
      expect(find.text("이 안 선택"), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });
  });
}
