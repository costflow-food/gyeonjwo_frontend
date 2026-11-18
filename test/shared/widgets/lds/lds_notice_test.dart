import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";

Future<void> _pump(WidgetTester tester, Widget notice, {double width = 720}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: notice),
          ),
        ),
      ),
    );

Color? _background(WidgetTester tester) =>
    (tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(LdsNotice),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration)
        .color;

void main() {
  testWidgets("tone sets the background and the title colour", (tester) async {
    for (final tone in LdsNoticeTone.values) {
      await _pump(tester, LdsNotice(tone: tone, title: "제목", message: "설명"));
      expect(_background(tester), tone.background);
      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byType(LdsNotice),
          matching: find.byType(RichText),
        ),
      );
      final title = (rich.text as TextSpan).children!.first as TextSpan;
      expect((title.children!.first as TextSpan).style!.color, tone.text);
    }
    expect(LdsNoticeTone.error.text, LdsColors.errorText);
  });

  testWidgets("title, message and the action on one line when wide", (
    tester,
  ) async {
    var tapped = 0;
    await _pump(
      tester,
      LdsNotice(
        tone: LdsNoticeTone.warning,
        icon: Icons.warning_amber,
        title: "검토 실행 준비 안 됨",
        message: "준비되면 이 안내는 저절로 사라집니다.",
        action: TextButton(
          onPressed: () => tapped++,
          child: const Text("다시 확인"),
        ),
      ),
    );
    expect(find.textContaining("검토 실행 준비 안 됨"), findsOneWidget);
    expect(find.textContaining("저절로 사라집니다"), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    final text = tester.getCenter(find.byType(RichText).first).dy;
    expect(tester.getCenter(find.text("다시 확인")).dy, closeTo(text, 12));
    await tester.tap(find.text("다시 확인"));
    expect(tapped, 1);
  });

  testWidgets("narrow: the action drops below the text", (tester) async {
    await _pump(
      tester,
      LdsNotice(
        message: "메일함 연결을 확인하지 못했습니다.",
        action: TextButton(onPressed: () {}, child: const Text("다시 확인")),
      ),
      width: 320,
    );
    expect(
      tester.getTopLeft(find.text("다시 확인")).dy,
      greaterThan(tester.getBottomLeft(find.byType(RichText).first).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("a banner has square corners", (tester) async {
    await _pump(tester, const LdsNotice(message: "안내", banner: true));
    final decoration =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(LdsNotice),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.borderRadius, isNull);
  });
}
