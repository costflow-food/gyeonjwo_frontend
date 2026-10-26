import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeonjwo_frontend/app/app_router.dart';
import 'package:gyeonjwo_frontend/main.dart';

void main() {
  Future<void> openQueue(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go('/');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('Preview advances all steps and opens the selected request', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await openQueue(tester, const Size(1440, 1000));
      await tester.tap(find.widgetWithText(OutlinedButton, '실행').at(1));
      await tester.pumpAndSettle();
      expect(find.text('디자인 시연 · D사 요청'), findsOneWidget);
      expect(find.bySemanticsLabel('검토 진행'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
      expect(find.text('시연 중'), findsOneWidget);
      expect(find.text('대기'), findsNWidgets(3));
      expect(find.text('검토 결과 보기'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text('완료')),
        findsOneWidget,
      );
      expect(find.text('대기'), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('검토카드가 준비되었어요'), findsOneWidget);
      await tester.tap(find.text('검토 결과 보기'));
      await tester.pumpAndSettle();
      expect(find.text('REQ-2026-1019-002 · 합성 시연 사례'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('Closing the dialog keeps the preview running', (tester) async {
    await openQueue(tester, const Size(1440, 1000));
    await tester.tap(find.widgetWithText(OutlinedButton, '실행').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('검토 진행 닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, '진행 보기').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.text('검토카드가 준비되었어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completed requests offer results without rerun actions', (
    tester,
  ) async {
    await openQueue(tester, const Size(1440, 1000));
    await tester.tap(find.widgetWithText(OutlinedButton, '실행').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('검토 진행 닫기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '결과 보기'), findsNWidgets(3));
    expect(find.text('다시 실행'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screens and large text remain scrollable', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openQueue(tester, const Size(375, 667));
    appRouter.go('/review-progress?requestId=REQ-2026-1019-003');
    await tester.pumpAndSettle();
    expect(find.text('요청의 근거를 모으고 있어요'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('검토 진행 닫기'));
    await tester.tap(find.byTooltip('검토 진행 닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
