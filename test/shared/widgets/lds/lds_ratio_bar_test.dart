import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";

Future<void> _pump(WidgetTester tester, List<LdsRatioSegment> segments) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 404, child: LdsRatioBar(segments: segments)),
          ),
        ),
      ),
    );

List<Rect> _parts(WidgetTester tester) => [
  for (final element
      in find
          .descendant(
            of: find.byType(LdsRatioBar),
            matching: find.byType(DecoratedBox),
          )
          .evaluate())
    tester.getRect(find.byWidget(element.widget)),
];

void main() {
  testWidgets("12 tall, rounded 6, parts by value with 4 between", (
    tester,
  ) async {
    await _pump(tester, const [
      LdsRatioSegment(label: "바른채소", value: 600, color: LdsColors.primary),
      LdsRatioSegment(label: "한라푸드", value: 400, color: LdsColors.title),
    ]);
    final parts = _parts(tester);
    expect(parts, hasLength(2));
    for (final part in parts) {
      expect(part.height, LdsRatioBar.height);
    }
    expect(parts[1].left - parts[0].right, LdsRatioBar.gap);
    // 400 wide after the gap, split 60 : 40.
    expect(parts[0].width, closeTo(240, 1));
    expect(parts[1].width, closeTo(160, 1));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(LdsRatioBar),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, LdsColors.primary);
    expect(decoration.borderRadius, BorderRadius.circular(6));
    // Names, not only colours, are read out.
    expect(find.bySemanticsLabel("바른채소 60%, 한라푸드 40%"), findsOneWidget);
  });

  testWidgets("nothing to show: one grey track", (tester) async {
    await _pump(tester, const [
      LdsRatioSegment(label: "바른채소", value: 0, color: LdsColors.primary),
    ]);
    final parts = _parts(tester);
    expect(parts, hasLength(1));
    expect(parts.single.width, 404);
  });

  test("supplier colours: orange, ink, grey (SSOT 3)", () {
    expect(ldsRatioColors, [
      LdsColors.primary,
      LdsColors.title,
      LdsColors.disabled,
    ]);
  });
}
