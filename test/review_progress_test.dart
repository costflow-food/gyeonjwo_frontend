import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/app/app_router.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/queue_tab.dart";
import "package:gyeonjwo_frontend/main.dart";

import "support/controlled_review_data_source.dart";

const _requestId = "REQ-2026-1019-003";

void main() {
  Future<void> openQueue(
    WidgetTester tester,
    ControlledReviewDataSource source, {
    Size size = const Size(1440, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go("/");
    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseReviewDataSourceProvider.overrideWithValue(source)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("Dialog keeps the route and waits for the actual response", (
    tester,
  ) async {
    final source = ControlledReviewDataSource();
    await openQueue(tester, source);
    await tester.tap(find.byType(QueueTab).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, "실행").first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(WorkQueueView), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, "/");
    expect(find.text("검토 결과 보기"), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text("검토 결과 보기"), findsNothing);
    source.succeed(_requestId);
    await tester.pumpAndSettle();
    expect(find.text("검토카드가 준비되었어요"), findsOneWidget);
    await tester.tap(find.text("검토 결과 보기"));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text("REQ-2026-1019-003 · 합성 시연 사례"), findsOneWidget);
    expect(source.calls[_requestId], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Closing and reopening keeps filters and one pending request", (
    tester,
  ) async {
    final source = ControlledReviewDataSource();
    await openQueue(tester, source);
    await tester.enterText(find.byType(TextFormField), "A사");
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, "실행").first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip("검토 진행 닫기"));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, "진행 보기"), findsOneWidget);
    expect(
      tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller
              ?.text ??
          tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
      "A사",
    );
    await tester.tap(find.widgetWithText(OutlinedButton, "진행 보기"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.calls[_requestId], 1);
    source.succeed(_requestId);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("검토 진행 닫기"));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, "결과 보기"), findsNWidgets(3));
    expect(source.calls[_requestId], 1);
  });

  testWidgets("Closing a dialog preserves the existing scroll position", (
    tester,
  ) async {
    final source = ControlledReviewDataSource();
    await openQueue(tester, source, size: const Size(1440, 600));
    final scroll = find.byType(SingleChildScrollView).last;
    await tester.drag(scroll, const Offset(0, -220));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0));
    final execute = find.widgetWithText(OutlinedButton, "실행").first;
    await tester.ensureVisible(execute);
    await tester.pumpAndSettle();
    final beforeOpen = scrollable.position.pixels;
    await tester.tap(execute);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip("검토 진행 닫기"));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, closeTo(beforeOpen, .1));
    source.succeed(_requestId);
    await tester.pumpAndSettle();
  });

  testWidgets("A failed result never becomes complete and can be retried", (
    tester,
  ) async {
    final source = ControlledReviewDataSource();
    await openQueue(tester, source);
    await tester.tap(find.widgetWithText(OutlinedButton, "실행").first);
    await tester.pump();
    source.fail(_requestId);
    await tester.pumpAndSettle();
    expect(find.text("검토 결과 보기"), findsNothing);
    final retry = find.descendant(
      of: find.byType(Dialog),
      matching: find.text("다시 시도"),
    );
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    expect(source.calls[_requestId], 2);
    source.succeed(_requestId);
    await tester.pumpAndSettle();
    expect(find.text("검토 결과 보기"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Small screens and large text remain scrollable", (tester) async {
    final source = ControlledReviewDataSource();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openQueue(tester, source, size: const Size(320, 640));
    final execute = find.widgetWithText(OutlinedButton, "실행").first;
    await tester.ensureVisible(execute);
    await tester.tap(execute);
    await tester.pump();
    source.succeed(_requestId);
    await tester.pumpAndSettle();
    expect(find.text("검토카드가 준비되었어요"), findsOneWidget);
    expect(tester.takeException(), isNull);
    final close = find.byTooltip("검토 진행 닫기");
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
