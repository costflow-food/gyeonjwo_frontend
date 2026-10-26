import 'package:flutter/material.dart';
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:gyeonjwo_frontend/app/app_router.dart';
import 'package:gyeonjwo_frontend/main.dart';

void main() {
  Future<void> showApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go('/');
    await tester.pumpAndSettle();
  }

  testWidgets('Desktop displays the work queue reference screen', (
    tester,
  ) async {
    await showApp(tester, const Size(1440, 900));
    expect(find.widgetWithText(ListTile, '업무 큐'), findsOneWidget);
    expect(find.text('흩어진 요청을, 한눈에 검토하세요.'), findsOneWidget);
    expect(find.text('[단가변경] 11월 냉동 딸기 공급단가 조정 안내'), findsOneWidget);
    expect(find.text('10월 상품 안내 및 정기 뉴스레터'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Review preview shows the three supplier comparison cards', (
    tester,
  ) async {
    await showApp(tester, const Size(1440, 900));
    await tester.tap(find.widgetWithText(OutlinedButton, '실행').first);
    await tester.pumpAndSettle();
    expect(find.text('냉동 딸기 단가 인상 요청'), findsOneWidget);
    expect(find.text('A사'), findsOneWidget);
    expect(find.text('B사'), findsOneWidget);
    expect(find.text('C사'), findsOneWidget);
    expect(find.text('확정 불가'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('업무 큐로'));
    await tester.pumpAndSettle();
    expect(find.text('흩어진 요청을, 한눈에 검토하세요.'), findsOneWidget);
  });

  testWidgets('Supplier evidence dialog opens from a card and closes', (
    tester,
  ) async {
    await showApp(tester, const Size(1440, 900));
    appRouter.go('/review');
    await tester.pumpAndSettle();
    final button = find.text('A사 상세 근거 보기');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('A사 상세 근거'), findsOneWidget);
    expect(find.text('월 비용 영향 +300,000원'), findsOneWidget);
    expect(find.text('비용 증가'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.textContaining('확인 필요'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('5,450,000원'),
      ),
      findsOneWidget,
    );
    expect(find.text('차액 교차 확인'), findsOneWidget);
    expect(find.text('직접 비교에서 제외한 자료'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('A사 상세 근거'), findsNothing);

    final candidate = find.text('B사 상세 근거 보기');
    await tester.ensureVisible(candidate);
    await tester.tap(candidate);
    await tester.pumpAndSettle();
    expect(find.text('월 비용 영향 확정 불가'), findsOneWidget);
    expect(find.text('비용 증가'), findsNothing);
    expect(find.text('확인 필요 2건 · 월 운송비, 월 기타 물류비'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('B사 상세 근거'), findsNothing);
  });

  testWidgets(
    'Manual sidebar choice survives resizing when enough space is available',
    (tester) async {
      await showApp(tester, const Size(1440, 900));
      await tester.tap(find.byTooltip('사이드바 접기'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '업무 큐'), findsNothing);
      expect(find.byTooltip('사이드바 펼치기'), findsOneWidget);
      tester.view.physicalSize = const Size(640, 480);
      await tester.pumpAndSettle();
      expect(find.byTooltip('사이드바 펼치기'), findsOneWidget);
      await tester.tap(find.byTooltip('사이드바 펼치기'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '업무 큐'), findsOneWidget);
      tester.view.physicalSize = const Size(520, 360);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '업무 큐'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sidebar folds at the content-space boundary and restores itself',
    (tester) async {
      await showApp(tester, const Size(640, 480));
      tester.view.physicalSize = const Size(461, 480);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '업무 큐'), findsOneWidget);

      tester.view.physicalSize = const Size(460, 480);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '업무 큐'), findsNothing);
      final button = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == '창을 넓히면 사이드바를 펼칠 수 있습니다',
        ),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);

      // Regression: the whole window can be narrower than the expanded sidebar.
      for (final width in [160.0, 56.0, 1.0]) {
        tester.view.physicalSize = Size(width, 480);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ListTile, '업무 큐'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(640, 480);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '업무 큐'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Auto folding does not undo a manual collapse', (tester) async {
    await showApp(tester, const Size(640, 480));
    await tester.tap(find.byTooltip('사이드바 접기'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(160, 480);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(640, 480);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '업무 큐'), findsNothing);
    await tester.tap(find.byTooltip('사이드바 펼치기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '업무 큐'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Supplier cards reflow between three, two and one columns', (
    tester,
  ) async {
    await showApp(tester, const Size(1440, 900));
    appRouter.go('/review');
    await tester.pumpAndSettle();
    final a = find.byKey(const ValueKey('supplier-A'));
    final b = find.byKey(const ValueKey('supplier-B'));
    final c = find.byKey(const ValueKey('supplier-C'));
    expect(tester.getTopLeft(a).dy, closeTo(tester.getTopLeft(b).dy, .1));
    expect(tester.getTopLeft(a).dy, closeTo(tester.getTopLeft(c).dy, .1));
    tester.view.physicalSize = const Size(1100, 700);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(a).dy, closeTo(tester.getTopLeft(b).dy, .1));
    expect(tester.getTopLeft(c).dy, greaterThan(tester.getTopLeft(a).dy));
    tester.view.physicalSize = const Size(640, 480);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(b).dy, greaterThan(tester.getTopLeft(a).dy));
    expect(tester.getTopLeft(c).dy, greaterThan(tester.getTopLeft(b).dy));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(1920, 1080),
    const Size(1440, 900),
    const Size(1280, 720),
    const Size(1024, 600),
    const Size(900, 480),
    const Size(800, 600),
    const Size(640, 360),
    const Size(520, 320),
    const Size(320, 640),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Both screens fit $size at text scale $scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await showApp(tester, size);
        expect(
          find.byTooltip(
            size.width >= 461 ? '사이드바 접기' : '창을 넓히면 사이드바를 펼칠 수 있습니다',
          ),
          findsOneWidget,
        );
        expect(find.byType(Drawer), findsNothing);
        expect(tester.takeException(), isNull);
        appRouter.go('/review');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('supplier-C')), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (size.width >= 520) {
          final horizontalScrolls = tester
              .widgetList<SingleChildScrollView>(
                find.byType(SingleChildScrollView),
              )
              .where((scroll) => scroll.scrollDirection == Axis.horizontal);
          expect(horizontalScrolls, isEmpty);
        }
        final evidence = find.text('A사 상세 근거 보기');
        await tester.ensureVisible(evidence);
        await tester.tap(evidence);
        await tester.pumpAndSettle();
        expect(find.text('A사 상세 근거'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
