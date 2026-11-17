import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

const _steps = [
  LdsStep("요청 확인", caption: "10.19 11:10"),
  LdsStep("후보 찾기"),
  LdsStep("견적 요청", caption: "지금"),
  LdsStep("회신"),
  LdsStep("검토 카드"),
];

Future<void> _pump(WidgetTester tester, int? current) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme(WorkspacePalette.lds),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 600,
          child: LdsStepBar(steps: _steps, current: current),
        ),
      ),
    ),
  ),
);

/// The step circles, left to right.
List<Container> _circles(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(LdsStepBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              (widget.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
      ),
    )
    .toList();

void main() {
  testWidgets("done are filled with a check, now has a light ring", (
    tester,
  ) async {
    await _pump(tester, 2);
    final circles = _circles(tester);
    expect(circles, hasLength(5));
    BoxDecoration deco(int index) =>
        circles[index].decoration! as BoxDecoration;
    // 1, 2 done: orange with a check.
    expect(deco(0).color, LdsColors.primary);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    // 3 now: orange, ringed 4px in light orange.
    expect(deco(2).color, LdsColors.primary);
    expect(deco(2).boxShadow!.single.spreadRadius, 4);
    expect(deco(2).boxShadow!.single.color, LdsColors.primaryLight);
    // 4, 5 to come: white with a light orange border.
    expect(deco(3).color, Colors.white);
    expect(deco(3).border!.top.color, LdsColors.primaryLight);
    for (final circle in circles) {
      expect(circle.constraints!.maxWidth, LdsStepBar.circle);
    }
  });

  testWidgets("the first step sits on the left edge, the last on the right", (
    tester,
  ) async {
    await _pump(tester, 2);
    final bar = tester.getRect(find.byType(LdsStepBar));
    final circles = find.descendant(
      of: find.byType(LdsStepBar),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            (widget.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      ),
    );
    expect(tester.getRect(circles.first).left, bar.left);
    expect(tester.getRect(circles.last).right, bar.right);
    // Names: first left-aligned, last right-aligned under their circles.
    expect(tester.getTopLeft(find.text("요청 확인")).dx, bar.left);
    expect(tester.getTopRight(find.text("검토 카드")).dx, bar.right);
    expect(find.text("10.19 11:10"), findsOneWidget);
  });

  testWidgets("all done, or no current step", (tester) async {
    await _pump(tester, 5);
    expect(find.byIcon(Icons.check), findsNWidgets(5));
    await _pump(tester, null);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(
      (_circles(tester)[0].decoration! as BoxDecoration).color,
      Colors.white,
    );
  });

  testWidgets("each step is read with its state", (tester) async {
    await _pump(tester, 2);
    expect(find.bySemanticsLabel("5단계 중 3단계 견적 요청, 지금 단계, 지금"), findsOneWidget);
    expect(
      find.bySemanticsLabel("5단계 중 1단계 요청 확인, 완료, 10.19 11:10"),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel("5단계 중 5단계 검토 카드, 남은 단계"), findsOneWidget);
  });
}
