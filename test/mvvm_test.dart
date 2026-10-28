import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/app/app_router.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/purchase_review_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_data_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";

class ControlledQueueDataSource implements WorkQueueDataSource {
  int calls = 0;
  bool fail = false;
  Completer<Map<String, dynamic>>? pending;

  @override
  Future<Map<String, dynamic>> fetchRequests() {
    calls++;
    if (fail) return Future.error(StateError("서버 응답 실패"));
    return pending?.future ??
        const PreviewWorkQueueDataSource(latency: Duration.zero)
            .fetchRequests();
  }
}

class CountingReviewDataSource implements PurchaseReviewDataSource {
  final calls = <String, int>{};
  bool fail = false;

  @override
  Future<Map<String, dynamic>> fetchReview(String requestId) {
    calls.update(requestId, (count) => count + 1, ifAbsent: () => 1);
    if (fail) return Future.error(StateError("상세 조회 실패"));
    return const PreviewPurchaseReviewDataSource(latency: Duration.zero)
        .fetchReview(requestId);
  }
}

class AlternateReviewDataSource implements PurchaseReviewDataSource {
  @override
  Future<Map<String, dynamic>> fetchReview(String requestId) async {
    final response = await const PreviewPurchaseReviewDataSource(
      latency: Duration.zero,
    ).fetchReview(requestId);
    return {
      ...response,
      "title": "API 응답으로 받은 요청 제목",
      "requestedUnitPrice": 5600,
      "reviewQuantity": 700,
      "monthlyCostImpact": 420000,
    };
  }
}

void main() {
  test("Queue exposes loading until the response arrives", () async {
    final source = ControlledQueueDataSource()
      ..pending = Completer<Map<String, dynamic>>();
    final container = ProviderContainer.test(
      overrides: [workQueueDataSourceProvider.overrideWithValue(source)],
    );
    final future = container.read(workQueueViewModelProvider.future);
    expect(container.read(workQueueViewModelProvider).isLoading, isTrue);
    source.pending!.complete({"requests": []});
    expect((await future).visibleRequests, isEmpty);
  });

  test("Queue combines status and search without fetching again", () async {
    final source = ControlledQueueDataSource();
    final container = ProviderContainer.test(
      overrides: [workQueueDataSourceProvider.overrideWithValue(source)],
    );
    final subscription = container.listen(
      workQueueViewModelProvider,
      (_, _) {},
    );
    final initial = await container.read(workQueueViewModelProvider.future);
    expect(initial.requests, hasLength(6));
    expect(initial.countFor("검토 대기"), 2);
    final viewModel = container.read(workQueueViewModelProvider.notifier);
    viewModel.selectStatus("검토 대기");
    viewModel.search(" d사 ");
    var state = container.read(workQueueViewModelProvider).requireValue;
    expect(state.visibleRequests.single.id, "REQ-2026-1019-002");
    expect(state.countFor("전체"), 6);
    viewModel.search("없는 거래처");
    state = container.read(workQueueViewModelProvider).requireValue;
    expect(state.visibleRequests, isEmpty);
    subscription.close();
    await container.pump();
    final retained = container.read(workQueueViewModelProvider).requireValue;
    expect(retained.selectedStatus, "검토 대기");
    expect(retained.query, "없는 거래처");
    expect(source.calls, 1);
  });

  test("A failed request can be retried and refreshed", () async {
    final source = ControlledQueueDataSource()..fail = true;
    final container = ProviderContainer.test(
      overrides: [workQueueDataSourceProvider.overrideWithValue(source)],
    );
    await expectLater(
      container.read(workQueueViewModelProvider.future),
      throwsStateError,
    );
    expect(container.read(workQueueViewModelProvider).hasError, isTrue);
    source.fail = false;
    container.read(workQueueViewModelProvider.notifier).refresh();
    expect(
      (await container.read(workQueueViewModelProvider.future)).requests,
      hasLength(6),
    );
    container.read(workQueueViewModelProvider.notifier).refresh();
    await container.read(workQueueViewModelProvider.future);
    expect(source.calls, 3);
  });

  test("Review results are retained independently for each request", () async {
    final source = CountingReviewDataSource();
    final container = ProviderContainer.test(
      overrides: [purchaseReviewDataSourceProvider.overrideWithValue(source)],
    );
    final firstProvider = purchaseReviewViewModelProvider("REQ-2026-1019-003");
    final secondProvider = purchaseReviewViewModelProvider("REQ-2026-1019-002");
    final subscription = container.listen(firstProvider, (_, _) {});
    final first = await container.read(firstProvider.future);
    subscription.close();
    await container.pump();
    final second = await container.read(secondProvider.future);
    expect(second.supplierName, "D사");
    expect(second.suppliers.first.letter, "D");
    expect(second.requestId, "REQ-2026-1019-002");
    expect(second.suppliers[1].monthlyTotalCost, isNull);
    expect(await container.read(firstProvider.future), same(first));
    expect(source.calls.values, everyElement(1));
    container.read(firstProvider.notifier).refresh();
    await container.read(firstProvider.future);
    expect(source.calls["REQ-2026-1019-003"], 2);
    expect(source.calls["REQ-2026-1019-002"], 1);
  });

  test("An unknown review ID does not return another request's data", () async {
    final container = ProviderContainer.test();
    await expectLater(
      container.read(purchaseReviewViewModelProvider("unknown").future),
      throwsStateError,
    );
  });

  testWidgets("Queue shows an error and reloads when retry is pressed", (
    tester,
  ) async {
    final source = ControlledQueueDataSource()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [workQueueDataSourceProvider.overrideWithValue(source)],
        child: const MyApp(),
      ),
    );
    appRouter.go("/");
    await tester.pumpAndSettle();
    expect(find.text("다시 시도"), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(source.calls, 1);
    source.fail = false;
    await tester.tap(find.text("다시 시도"));
    await tester.pumpAndSettle();
    expect(find.text("총 6건 · 최신 수신순"), findsOneWidget);
    expect(source.calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Review retries manually and keeps the selected request ID", (
    tester,
  ) async {
    final source = CountingReviewDataSource()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseReviewDataSourceProvider.overrideWithValue(source)],
        child: const MyApp(),
      ),
    );
    appRouter.go("/review?requestId=REQ-2026-1019-002");
    await tester.pumpAndSettle();
    expect(find.text("다시 시도"), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(source.calls["REQ-2026-1019-002"], 1);
    source.fail = false;
    await tester.tap(find.text("다시 시도"));
    await tester.pumpAndSettle();
    expect(find.text("REQ-2026-1019-002 · 합성 시연 사례"), findsOneWidget);
    expect(source.calls["REQ-2026-1019-002"], 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "Zero matches show no page and clearing search restores page one",
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final source = ControlledQueueDataSource();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [workQueueDataSourceProvider.overrideWithValue(source)],
            child: const MyApp(),
          ),
        );
        appRouter.go("/");
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), "없는 검색 결과");
        await tester.pumpAndSettle();
        expect(find.text("총 0건 · 최신 수신순"), findsOneWidget);
        expect(find.text("—"), findsOneWidget);
        expect(find.bySemanticsLabel("페이지 없음"), findsOneWidget);
        expect(find.bySemanticsLabel("현재 페이지 1"), findsNothing);
        for (final label in ["이전 페이지", "다음 페이지"]) {
          expect(
            tester.getSemantics(find.bySemanticsLabel(label)),
            matchesSemantics(
              label: label,
              isButton: true,
              hasEnabledState: true,
              isEnabled: false,
              hasTapAction: false,
            ),
          );
        }
        await tester.enterText(find.byType(TextFormField), "");
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text("총 6건 · 최신 수신순"));
        await tester.pumpAndSettle();
        expect(find.text("—"), findsNothing);
        expect(find.bySemanticsLabel("현재 페이지 1"), findsOneWidget);
        expect(source.calls, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets("Selecting a queue request loads that request's review", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go("/");
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, "실행").at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토 결과 보기'));
    await tester.pumpAndSettle();
    expect(find.text("REQ-2026-1019-002 · 합성 시연 사례"), findsOneWidget);
    expect(find.text("D사"), findsOneWidget);
    expect(find.text("D사 · 냉동 · 무가당 · 10kg/박스"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "Review summary uses response values instead of preview constants",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            purchaseReviewDataSourceProvider.overrideWithValue(
              AlternateReviewDataSource(),
            ),
          ],
          child: const MyApp(),
        ),
      );
      appRouter.go("/review?requestId=REQ-2026-1019-003");
      await tester.pumpAndSettle();
      expect(find.text("API 응답으로 받은 요청 제목"), findsOneWidget);
      expect(find.text("5,600 원/kg", findRichText: true), findsOneWidget);
      expect(find.text("700 kg", findRichText: true), findsOneWidget);
      expect(find.text("+420,000 원", findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
