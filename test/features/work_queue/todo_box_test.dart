import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/case_progress.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";

Future<void> _pump(WidgetTester tester, TodoBox box) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 800, child: box),
        ),
      ),
    ),
  );
}

void main() {
  // Box padding 18 + 1px border.
  const inset = 19.0;

  testWidgets("buttons sit at the box's right edge", (tester) async {
    await _pump(
      tester,
      TodoBox(
        title: "구매안을 골라 주세요",
        actions: [
          LdsButton(
            label: "다시 검토",
            variant: LdsButtonVariant.ghostNeutral,
            onPressed: () {},
          ),
          LdsButton(label: "검토 카드 보기", onPressed: () {}),
        ],
      ),
    );
    final boxRight = tester.getTopRight(find.byType(TodoBox)).dx;
    expect(
      tester.getTopRight(find.widgetWithText(LdsButton, "검토 카드 보기")).dx,
      closeTo(boxRight - inset, 1),
    );
    // In order, the last one rightmost.
    expect(
      tester.getTopRight(find.widgetWithText(LdsButton, "다시 검토")).dx,
      lessThan(
        tester.getTopLeft(find.widgetWithText(LdsButton, "검토 카드 보기")).dx,
      ),
    );
  });

  testWidgets("with leading text the buttons still reach the right edge", (
    tester,
  ) async {
    await _pump(
      tester,
      TodoBox(
        title: "견적을 요청할 업체를 골라 주세요",
        leading: const Text("2 / 3곳 선택"),
        actions: [LdsButton(label: "견적 요청", onPressed: () {})],
      ),
    );
    final boxLeft = tester.getTopLeft(find.byType(TodoBox)).dx;
    final boxRight = tester.getTopRight(find.byType(TodoBox)).dx;
    expect(
      tester.getTopLeft(find.text("2 / 3곳 선택")).dx,
      closeTo(boxLeft + inset, 1),
    );
    expect(
      tester.getTopRight(find.widgetWithText(LdsButton, "견적 요청")).dx,
      closeTo(boxRight - inset, 1),
    );
  });
}
