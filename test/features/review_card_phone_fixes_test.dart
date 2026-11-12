import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/purchase_review_view.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/counter_offer_panel.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/review_card_content.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// Phone-only fixes on the review card, drawn at 360×760.

const _longName = "주식회사 한국프리미엄식자재유통센터 경기남부지점";

/// Loads a card; every decision fails (the fake has no submitDecision).
class _FailingReviews implements PurchaseReviewDataSource {
  @override
  Future<Map<String, dynamic>> fetchReviewCard(String caseId) async => {
    "data": {
      "case_id": caseId,
      "review_revision": 1,
      "input_revision": 1,
      "review_outcome": "OPTIONS_READY",
      "created_at": "2026-11-11T05:20:00Z",
      "plans": [
        for (final type in ["SPLIT", "KEEP", "SWITCH"])
          {
            "plan_id": "p-$type",
            "plan_type": type,
            "validation_status": "VALID",
            "total_amount": "1724000",
            "allocations": [
              {
                "supplier_id": "s1",
                "supplier_name": "한빛농산",
                "quantity": "60",
                "unit": "박스",
                "unit_price": "17800",
              },
            ],
          },
      ],
      "allowed_actions": ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
    },
  };

  @override
  Future<Map<String, dynamic>> fetchQuotes(String caseId) async => {
    "data": {
      "items": [
        for (final id in ["q1", "q2", "q3", "q4"])
          {
            "quote_id": id,
            "version_no": 1,
            "supplier_id": "s-$id",
            "supplier_name": "한빛농산 $id",
            "unit_price": "17800",
            "unit": "박스",
          },
      ],
    },
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ReviewCard _card({
  String? planId = "p-KEEP",
  CounterOffer? offer,
  List<String> allowedActions = const ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
}) => ReviewCard(
  caseId: "c1",
  reviewRevision: 1,
  inputRevision: 1,
  isStale: false,
  outcome: ReviewOutcome.optionsReady,
  createdAt: "2026-11-11T08:20:00Z",
  plans: [
    ResponsePlan(
      planId: planId,
      planType: "KEEP",
      validationStatus: "VALID",
      totalAmount: "2750000",
      allocations: const [
        PlanAllocation(
          supplierId: "s1",
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
  unresolved: const [],
  allowedActions: allowedActions,
);

Future<void> _pumpPhone(
  WidgetTester tester,
  Widget home, {
  List overrides = const [],
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _content(ReviewCard card) =>
    ReviewCardContent(review: PurchaseReview(card: card, quotes: const []));

void main() {
  testWidgets("a failed 확인하고 보관 is said while the page is scrolled down", (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      const PurchaseReviewView(caseId: "c1"),
      overrides: [
        purchaseReviewDataSourceProvider.overrideWithValue(_FailingReviews()),
      ],
    );
    await tester.drag(
      find.byKey(const ValueKey("review-card-scroll")),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("확인하고 보관"));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text("확인하고 보관"),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text("서버 응답을 확인하지 못했습니다."),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("a plan that cannot be chosen says why under its button", (
    tester,
  ) async {
    await _pumpPhone(tester, _content(_card(planId: null)));
    expect(find.text("이 안 선택"), findsOneWidget);
    expect(find.text("서버가 이 안의 ID를 보내지 않아 선택할 수 없습니다."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a plan that can be chosen has no reason line", (tester) async {
    await _pumpPhone(tester, _content(_card()));
    expect(find.text("이 안 선택"), findsOneWidget);
    expect(find.textContaining("선택할 수 없습니다"), findsNothing);
  });

  testWidgets("a long supplier name stays inside the counter-offer title", (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      _content(
        _card(
          offer: const CounterOffer(
            status: "PROPOSE",
            target: CounterOfferTarget(
              supplierId: "s2",
              supplierName: _longName,
              targetUnitPrice: "17200",
            ),
          ),
        ),
      ),
    );
    final name = find.descendant(
      of: find.byType(CounterOfferPanel),
      matching: find.text(_longName),
    );
    expect(name, findsOneWidget);
    expect(tester.getRect(name).right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets("without the pinned bar the page ends above the system bar", (
    tester,
  ) async {
    EdgeInsetsGeometry? padding() => tester
        .widget<SingleChildScrollView>(
          find.byKey(const ValueKey("review-card-scroll")),
        )
        .padding;

    await _pumpPhone(
      tester,
      _content(_card(allowedActions: const [])),
      bottomInset: 48,
    );
    expect(find.text("확인하고 보관"), findsNothing);
    expect(padding(), const EdgeInsets.fromLTRB(16, 0, 16, 72));

    await _pumpPhone(tester, _content(_card()), bottomInset: 48);
    expect(find.text("확인하고 보관"), findsOneWidget);
    expect(padding(), const EdgeInsets.fromLTRB(16, 0, 16, 24));
  });
}
