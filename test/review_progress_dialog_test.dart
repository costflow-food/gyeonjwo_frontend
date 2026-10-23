import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/widgets/review_progress_dialog.dart";

void main() {
  Future<List<String>> showDialogAt(
    WidgetTester tester,
    Size size, {
    required int currentStep,
    bool demo = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewProgressDialog(
            supplier: "A사",
            currentStep: currentStep,
            demo: demo,
            onClose: () => calls.add("close"),
            onGoToQueue: () => calls.add("queue"),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets("Demo progress shows the active step and demo notices", (
    tester,
  ) async {
    await showDialogAt(
      tester,
      const Size(1250, 780),
      currentStep: 0,
      demo: true,
    );
    expect(find.text("디자인 시연 · A사 요청"), findsOneWidget);
    expect(find.text("시연 중"), findsOneWidget);
    expect(find.text("대기"), findsNWidgets(3));
    expect(find.text("큐로 이동해도 시연은 계속됩니다."), findsOneWidget);
    expect(find.textContaining("합성 사례의 화면 전환 시연입니다."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Product progress hides demo wording and marks done steps", (
    tester,
  ) async {
    await showDialogAt(tester, const Size(1250, 780), currentStep: 2);
    expect(find.text("A사 요청"), findsOneWidget);
    expect(find.text("완료"), findsNWidgets(2));
    expect(find.text("진행 중"), findsOneWidget);
    expect(find.text("대기"), findsOneWidget);
    expect(find.textContaining("시연"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Narrow screens keep every step and action reachable", (
    tester,
  ) async {
    final calls = await showDialogAt(
      tester,
      const Size(360, 640),
      currentStep: 1,
      demo: true,
    );
    expect(tester.takeException(), isNull);
    for (final step in reviewProgressSteps) {
      expect(find.text(step), findsOneWidget);
    }
    await tester.tap(find.byTooltip("닫기"));
    await tester.tap(find.widgetWithText(OutlinedButton, "업무 큐"));
    expect(calls, ["close", "queue"]);
  });
}
