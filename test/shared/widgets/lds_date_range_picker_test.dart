import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// 2026-11-18 is a Wednesday.
final _today = DateTime(2026, 11, 18);

Future<List<DateTimeRange>> _pump(
  WidgetTester tester, {
  double width = 1440,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final picked = <DateTimeRange>[];
  var value = LdsQuickRange.thisWeek.rangeFor(_today);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => LdsDateRangeButton(
                value: value,
                today: _today,
                onChanged: (range) => setState(() {
                  picked.add(range);
                  value = range;
                }),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return picked;
}

LdsButton _button(WidgetTester tester, String label) =>
    tester.widget<LdsButton>(find.widgetWithText(LdsButton, label));

void main() {
  test("quick ranges: this week is Sunday to Saturday", () {
    final week = LdsQuickRange.thisWeek.rangeFor(_today);
    expect(week.start, DateTime(2026, 11, 15));
    expect(week.end, DateTime(2026, 11, 21));
    final month = LdsQuickRange.thisMonth.rangeFor(_today);
    expect(month.start, DateTime(2026, 11, 1));
    expect(month.end, DateTime(2026, 11, 30));
    expect(
      formatLdsDateRange(LdsQuickRange.today.rangeFor(_today)),
      "2026. 11. 18",
    );
  });

  testWidgets("the button shows the range, 36 tall", (tester) async {
    await _pump(tester);
    expect(find.text("2026. 11. 15 - 2026. 11. 21"), findsOneWidget);
    expect(tester.getSize(find.byType(LdsDateRangeButton)).height, 36);
  });

  testWidgets("popover: two months under the button's right edge, "
      "quick range then apply", (tester) async {
    final picked = await _pump(tester);
    await tester.tap(find.byType(LdsDateRangeButton));
    await tester.pumpAndSettle();
    expect(find.text("2026. 11"), findsOneWidget);
    expect(find.text("2026. 12"), findsOneWidget);
    final panel = find.byType(LdsDateRangePanel);
    expect(
      tester.getTopRight(panel).dx,
      closeTo(tester.getTopRight(find.byType(LdsDateRangeButton)).dx, 1),
    );
    await tester.tap(find.text("이번 달"));
    await tester.pumpAndSettle();
    expect(find.text("2026. 11. 1 - 2026. 11. 30"), findsOneWidget);
    // The range only fills the calendar; '적용' confirms.
    expect(picked, isEmpty);
    await tester.tap(find.widgetWithText(LdsButton, "적용"));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(picked.single.start, DateTime(2026, 11, 1));
    expect(picked.single.end, DateTime(2026, 11, 30));
    expect(find.text("2026. 11. 1 - 2026. 11. 30"), findsOneWidget);
  });

  testWidgets("picking days: apply waits for the end; Esc closes unchanged", (
    tester,
  ) async {
    final picked = await _pump(tester);
    await tester.tap(find.byType(LdsDateRangeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel("2026년 11월 3일"));
    await tester.pump();
    expect(_button(tester, "적용").onPressed, isNull);
    await tester.tap(find.bySemanticsLabel("2026년 11월 9일"));
    await tester.pump();
    expect(_button(tester, "적용").onPressed, isNotNull);
    expect(find.text("2026. 11. 3 - 2026. 11. 9"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(LdsDateRangePanel), findsNothing);
    expect(picked, isEmpty);
    expect(find.text("2026. 11. 15 - 2026. 11. 21"), findsOneWidget);
  });

  testWidgets("under 744: a bottom sheet with one month", (tester) async {
    await _pump(tester, width: 700);
    await tester.tap(find.byType(LdsDateRangeButton));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text("2026. 11"), findsOneWidget);
    expect(find.text("2026. 12"), findsNothing);
    await tester.tap(find.widgetWithText(LdsButton, "취소"));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
