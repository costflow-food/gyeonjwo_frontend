import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/purchase_review_view.dart";
import "package:gyeonjwo_frontend/features/review_progress/data/review_progress_repository_impl.dart";
import "package:gyeonjwo_frontend/features/review_progress/domain/review_progress_repository.dart";
import "package:gyeonjwo_frontend/features/review_progress/presentation/review_progress_view.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/candidate.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/candidate_selection.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// Phone screens drawn at 360×760 with long Korean text: a layout overflow
/// fails the test.

class _Reviews implements PurchaseReviewDataSource {
  @override
  Future<Map<String, dynamic>> fetchReviewCard(String caseId) async => {
    "data": {
      "case_id": caseId,
      "review_revision": 2,
      "input_revision": 3,
      "review_outcome": "OPTIONS_READY",
      "created_at": "2026-11-11T05:20:00Z",
      "plans": [
        for (final (type, status, total) in [
          ("SPLIT", "VALID", "1724000"),
          ("KEEP", "VALID", "1850000"),
          ("SWITCH", "CONDITIONAL", "1690000"),
        ])
          {
            "plan_id": "p-$type",
            "plan_type": type,
            "validation_status": status,
            "total_amount": total,
            "allocations": [
              {
                "supplier_id": "s1",
                "supplier_name": "그린팜 농업회사법인 유한회사",
                "quantity": "60",
                "unit": "박스",
                "unit_price": "17800",
              },
              {
                "supplier_id": "s2",
                "supplier_name": "한빛농산",
                "quantity": "40",
                "unit": "박스",
                "unit_price": "18500",
              },
            ],
            "conditions": ["최소 주문 수량 미확인"],
          },
      ],
      "questions": [
        {
          "supplier_name": "새벽농장",
          "field": "spec",
          "priority": "HIGH",
          "reason": "회신에 10kg 박스 여부가 없어 규격을 확인해야 합니다.",
          "break_even_amount": "1790000",
        },
      ],
      "counter_offer": {
        "status": "PROPOSE",
        "reason": "대안 총액이 인상안보다 낮습니다.",
        "target": {
          "supplier_id": "s2",
          "supplier_name": "한빛농산",
          "target_unit_price": "17200",
          "conditions": ["12월 출고분부터"],
        },
        "reference": {
          "status": "OK",
          "unit": "박스",
          "requested_unit_price": "18500",
          "previous_unit_price": "16000",
          "alternative_total": "1724000",
          "allowed_range": ["16800", "17600"],
        },
      },
      "allowed_actions": ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
    },
  };

  @override
  Future<Map<String, dynamic>> fetchQuotes(String caseId) async => {
    "data": {
      "items": [
        {
          "quote_id": "q1",
          "version_no": 1,
          "supplier_id": "s1",
          "supplier_name": "그린팜 농업회사법인 유한회사",
          "unit_price": "17800",
          "unit": "박스",
          "tax_basis": "EXCLUSIVE",
          "effective_from": "2026-11-15",
          "valid_until": "2026-11-30",
          "costs": [
            {"cost_type": "SHIPPING", "amount": "3000"},
          ],
        },
      ],
    },
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Candidates implements WorkQueueRepository {
  @override
  Future<CandidateSet> getCandidates(String caseId) async => CandidateSet(
    id: "set-1",
    revision: 1,
    allowedActions: const [WorkCaseAction.selectCandidates],
    selectedSupplierIds: const ["s1"],
    candidates: [
      for (final name in ["그린팜 농업회사법인 유한회사", "새벽농장", "한마음유통"])
        Candidate(
          supplierId: name == "그린팜 농업회사법인 유한회사" ? "s1" : name,
          name: name,
          handlingEvidence: "국내산 깐양파 10kg 박스 정기 공급 이력이 있습니다.",
          reason: "최근 3개월 단가가 가장 낮고 납기를 지켰습니다.",
          contactEmail: "sales@greenfarm-example.co.kr",
          preferenceScore: 82,
          webCandidate: true,
          checks: const [
            CandidateCheck(label: "원산지", state: CheckState.met),
            CandidateCheck(label: "규격", state: CheckState.unmet),
            CandidateCheck(
              label: "HACCP",
              state: CheckState.unknown,
              required: false,
            ),
          ],
        ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Progress implements ReviewProgressRepository {
  @override
  Future<CaseProgress> getProgress(String caseId) async => CaseProgress(
    caseId: caseId,
    status: "Running",
    processingStep: "SELECTING_CANDIDATES",
    inputRevision: 1,
  );
}

Future<void> _pumpPhone(
  WidgetTester tester,
  Widget child, {
  required List overrides,
  double textScale = 1,
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

WorkCase _case() => WorkCase(
  id: "c1",
  initialMailId: "m1",
  title: "[단가 인상 안내] 깐양파 10kg 11월 공급가 조정",
  sender: "kim@example.invalid",
  receivedAt: "2026-11-11T00:12:00Z",
  status: WorkCaseStatus.fromCode("Running"),
  statusCode: "Running",
  processingStep: "SELECTING_CANDIDATES",
  stepMessage: "",
  inputRevision: 1,
  attachmentCount: 0,
  itemName: "깐양파",
  allowedActions: const [WorkCaseAction.selectCandidates],
);

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets("review card fits a phone at text scale $scale", (
      tester,
    ) async {
      await _pumpPhone(
        tester,
        const PurchaseReviewView(caseId: "c1"),
        overrides: [
          purchaseReviewDataSourceProvider.overrideWithValue(_Reviews()),
        ],
        textScale: scale,
      );
      expect(find.text("검토 카드"), findsOneWidget);
      expect(find.text("확인하고 보관"), findsOneWidget);
      // Scroll down to the first plan's button.
      // The page scrolls under a finger.
      final scroll = find.byKey(const ValueKey("review-card-scroll"));
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      await tester.drag(scroll, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      // Every plan is on the page at once, in the server's order, and
      // nothing on it scrolls sideways.
      final totals = [
        for (final total in ["1,724,000원", "1,850,000원", "1,690,000원"])
          tester.getRect(find.text(total)),
      ];
      expect(totals[0].top, lessThan(totals[1].top));
      expect(totals[1].top, lessThan(totals[2].top));
      for (final rect in totals) {
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
      expect(
        tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where((scrollable) => scrollable.axis == Axis.horizontal),
        isEmpty,
      );
      // The lowest plan that can be chosen starts open; tapping another
      // opens that one instead.
      expect(find.text("선택"), findsOneWidget);
      expect(find.text("수용"), findsNothing);
      await tester.ensureVisible(find.text("전량 전환"));
      await tester.tap(find.text("전량 전환"));
      await tester.pumpAndSettle();
      expect(find.text("선택"), findsNothing);
      expect(find.text("수용"), findsOneWidget);
      await tester.ensureVisible(find.text("전량 전환"));
      await tester.tap(find.text("전량 전환"));
      await tester.pumpAndSettle();
      expect(find.text("수용"), findsNothing);
      // Scroll through the rest of the card.
      await tester.ensureVisible(find.text("견적과 근거"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets("candidate page fits a phone at text scale $scale", (
      tester,
    ) async {
      await _pumpPhone(
        tester,
        CandidateSelection(workCase: _case(), page: true),
        overrides: [
          workQueueRepositoryProvider.overrideWithValue(_Candidates()),
        ],
        textScale: scale,
      );
      expect(find.text("견적 요청 대상 선택"), findsOneWidget);
      expect(find.text("선택한 1곳에 견적 요청").hitTestable(), findsOneWidget);
      await tester.dragUntilVisible(
        find.text("한마음유통"),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("review progress opens as a bottom sheet on a phone", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showReviewProgressDialog(
                  context,
                  caseId: "c1",
                  title: "[단가 인상 안내] 깐양파 10kg 11월 공급가 조정",
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewProgressRepositoryProvider.overrideWithValue(_Progress()),
          workCaseChangesProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: MaterialApp.router(
          theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text("검토 진행"), findsWidgets);
    expect(tester.takeException(), isNull);
    // Close it so the polling timer stops before the test ends.
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
  });
}
