import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeonjwo_frontend/features/analysis_stop/presentation/analysis_stop_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, {VoidCallback? onOpenSource}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAnalysisStopDialog(context, onOpenSource: onOpenSource),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('중단 사유와 원문 확인 버튼만 표시한다', (tester) async {
    await open(tester);

    expect(find.text('분석을 중단했습니다'), findsOneWidget);
    expect(find.text('비교 가능한 품목 규격'), findsOneWidget);
    expect(find.text('원문 확인'), findsOneWidget);
    expect(find.text('업무 큐'), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('원문 확인은 콜백을 호출하고 대화상자를 유지한다', (tester) async {
    var opened = false;
    await open(tester, onOpenSource: () => opened = true);

    await tester.tap(find.text('원문 확인'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.text('분석을 중단했습니다'), findsOneWidget);
  });

  testWidgets('X 버튼과 배경 클릭으로 닫힌다', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('분석을 중단했습니다'), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('분석을 중단했습니다'), findsNothing);
  });

  for (final size in const [Size(1920, 1080), Size(640, 360), Size(320, 640)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('대화상자가 $size, 글자 배율 $scale에서 넘치지 않는다', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await open(tester);

        expect(find.text('원문 확인'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
