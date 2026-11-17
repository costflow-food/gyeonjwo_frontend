import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// The web app runs on desktop browsers, so sizes are checked under a desktop
/// platform (compact visual density by default).
Future<void> _pump(WidgetTester tester, Widget child) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 800, child: Center(child: child)),
        ),
      ),
    ),
  );
}

Color? _fill(WidgetTester tester, Finder finder) {
  final box = tester.widget<Container>(
    find.descendant(of: finder, matching: find.byType(Container)).first,
  );
  return (box.decoration as BoxDecoration?)?.color;
}

void main() {
  group("LdsButton (SSOT 7.4)", () {
    for (final (size, height) in [
      (LdsButtonSize.small, 28.0),
      (LdsButtonSize.medium, 36.0),
      (LdsButtonSize.large, 48.0),
    ]) {
      testWidgets("${size.name} is $height tall", (tester) async {
        await _pump(
          tester,
          LdsButton(label: "확인", size: size, onPressed: () {}),
        );
        expect(tester.getSize(find.byType(FilledButton)).height, height);
      });
    }

    testWidgets("large uses radius 6, medium radius 4", (tester) async {
      RoundedRectangleBorder shape(WidgetTester tester) {
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        return button.style!.shape!.resolve({})! as RoundedRectangleBorder;
      }

      await _pump(tester, LdsButton(label: "확인", onPressed: () {}));
      expect(shape(tester).borderRadius, BorderRadius.circular(4));
      await _pump(
        tester,
        LdsButton(label: "확인", size: LdsButtonSize.large, onPressed: () {}),
      );
      expect(shape(tester).borderRadius, BorderRadius.circular(6));
    });

    testWidgets("loading hides the label but keeps the width", (tester) async {
      await _pump(tester, LdsButton(label: "설정 저장", onPressed: () {}));
      final idle = tester.getSize(find.byType(FilledButton));

      var pressed = 0;
      await _pump(
        tester,
        LdsButton(label: "설정 저장", loading: true, onPressed: () => pressed++),
      );
      expect(tester.getSize(find.byType(FilledButton)), idle);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)),
        const Size.square(20),
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(pressed, 0);
    });

    testWidgets("outlined has a #D1D6DC border and orange text", (
      tester,
    ) async {
      await _pump(
        tester,
        LdsButton(
          label: "보내지 않음",
          variant: LdsButtonVariant.outlined,
          onPressed: () {},
        ),
      );
      final style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      expect(style.side!.resolve({})!.color, LdsColors.borderStrong);
      expect(style.foregroundColor!.resolve({}), LdsColors.primary);
      expect(
        style.foregroundColor!.resolve({WidgetState.disabled}),
        LdsColors.disabled,
      );
    });

    testWidgets("icon button is 36 square", (tester) async {
      await _pump(
        tester,
        LdsIconButton(icon: Icons.search, tooltip: "검색", onPressed: () {}),
      );
      expect(
        tester.getSize(find.byType(OutlinedButton)),
        const Size.square(36),
      );
    });
  });

  group("LdsTag · LdsBadge (SSOT 4)", () {
    testWidgets("tag sizes are 24 and 28 tall", (tester) async {
      await _pump(tester, const LdsTag("대기"));
      expect(tester.getSize(find.byType(LdsTag)).height, 24);
      await _pump(tester, const LdsTag("대기", size: LdsTagSize.medium));
      expect(tester.getSize(find.byType(LdsTag)).height, 28);
    });

    testWidgets("weak tags use the 4.1 colour table", (tester) async {
      await _pump(tester, const LdsTag("진행 중", tone: LdsTagTone.progressing));
      expect(_fill(tester, find.byType(LdsTag)), const Color(0xFFE5F5FF));
      final text = tester.widget<Text>(find.text("진행 중"));
      expect(text.style!.color, const Color(0xFF3D94FF));
      expect(text.style!.fontWeight, FontWeight.w400);
    });

    testWidgets("a one-digit badge is a 20px circle, more digits a pill", (
      tester,
    ) async {
      await _pump(tester, const LdsBadge(3, tone: LdsBadgeTone.primary));
      expect(tester.getSize(find.byType(LdsBadge)), const Size(20, 20));
      expect(_fill(tester, find.byType(LdsBadge)), LdsColors.primary);

      await _pump(tester, const LdsBadge(128));
      final size = tester.getSize(find.byType(LdsBadge));
      expect(size.height, 20);
      expect(size.width, greaterThan(20));
      expect(_fill(tester, find.byType(LdsBadge)), LdsColors.badgeNeutralBg);
    });
  });

  group("LdsToggle · LdsRadio (SSOT 5, 6.2)", () {
    testWidgets("toggle sizes, colours and taps", (tester) async {
      var value = false;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LdsToggle(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      final track = find.byType(AnimatedContainer);
      expect(tester.getSize(track), const Size(32, 20));
      await tester.tap(find.byType(LdsToggle));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final on = tester.widget<AnimatedContainer>(track);
      expect((on.decoration! as BoxDecoration).color, LdsColors.primary);

      await _pump(
        tester,
        const LdsToggle(
          value: false,
          size: LdsToggleSize.small,
          onChanged: null,
        ),
      );
      expect(tester.getSize(track), const Size(28, 16));
      final off = tester.widget<AnimatedContainer>(track);
      expect((off.decoration! as BoxDecoration).color, LdsColors.lineSoft);
    });

    testWidgets("radio is 24px and reports the chosen value", (tester) async {
      String? chosen;
      await _pump(
        tester,
        LdsRadio<String>(
          value: "격식체",
          groupValue: null,
          onChanged: (v) => chosen = v,
        ),
      );
      expect(tester.getSize(find.byType(LdsRadio<String>)).width, 24);
      await tester.tap(find.byType(LdsRadio<String>));
      expect(chosen, "격식체");
    });
  });

  group("LdsDialog (SSOT 8.1)", () {
    testWidgets("title, white frame and a 32px close button", (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => LdsButton(
            label: "열기",
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  const LdsDialog(title: "메일 초안·발송", child: Text("본문")),
            ),
          ),
        ),
      );
      await tester.tap(find.text("열기"));
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text("메일 초안·발송"));
      expect(title.style!.fontSize, 21);
      expect(title.style!.fontWeight, FontWeight.w700);
      expect(
        tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
        Colors.white,
      );
      final close = find.byType(LdsDialogCloseButton);
      expect(tester.getSize(close), const Size.square(32));
      final dialogRect = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      final closeRect = tester.getRect(close);
      // 16 from the dialog panel's right edge.
      expect(dialogRect.right - closeRect.right, closeTo(16, 0.5));

      // The header (and its divider) spans the whole dialog.
      final header = find
          .ancestor(of: find.text("메일 초안·발송"), matching: find.byType(Container))
          .first;
      expect(tester.getSize(header).width, closeTo(dialogRect.width, 0.5));

      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(LdsDialog), findsNothing);
    });
  });

  group("tables (SSOT 9)", () {
    testWidgets("key-value table: 112 label column, rows at least 44", (
      tester,
    ) async {
      await _pump(
        tester,
        const LdsKeyValueTable(
          rows: [
            LdsKeyValueRow("담당자", text: "김영업"),
            LdsKeyValueRow("이메일", text: "sales@a-supplier.example.com"),
          ],
        ),
      );
      final label = find
          .ancestor(of: find.text("담당자"), matching: find.byType(Container))
          .first;
      expect(tester.getSize(label).width, 112);
      expect(tester.getSize(label).height, greaterThanOrEqualTo(44));
      expect(_fillOf(tester, label), LdsColors.canvas);
      // Value starts 16 after the label column.
      expect(
        tester.getTopLeft(find.text("김영업")).dx - tester.getTopRight(label).dx,
        16,
      );
    });

    testWidgets("list table: 40 header, latest row tinted", (tester) async {
      await _pump(
        tester,
        const LdsListTable(
          columns: [LdsColumn("적용일"), LdsColumn("단가")],
          rows: [
            LdsListRow(latest: true, [Text("2026.11.01"), Text("5,500원/kg")]),
            LdsListRow([Text("2026.05.01"), Text("5,000원/kg")]),
          ],
        ),
      );
      final header = find
          .ancestor(of: find.text("적용일"), matching: find.byType(Container))
          .first;
      expect(tester.getSize(header).height, 40);
      final latest = find.ancestor(
        of: find.text("2026.11.01"),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color == LdsColors.primaryRow,
        ),
      );
      expect(latest, findsOneWidget);
      expect(tester.getSize(latest).height, greaterThanOrEqualTo(48));
    });

    testWidgets("compare table marks the recommended column", (tester) async {
      await _pump(
        tester,
        const LdsCompareTable(
          options: [
            LdsCompareOption("한라푸드"),
            LdsCompareOption("바른채소", recommended: true),
          ],
          rows: [
            LdsCompareRow("단가", [Text("5,800원/kg"), Text("5,400원/kg")]),
          ],
        ),
      );
      expect(find.text("추천"), findsOneWidget);
      final recommended = find.ancestor(
        of: find.text("5,400원/kg"),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color == LdsColors.primaryRow,
        ),
      );
      expect(recommended, findsOneWidget);
      final plain = find.ancestor(
        of: find.text("5,800원/kg"),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color == LdsColors.primaryRow,
        ),
      );
      expect(plain, findsNothing);
      // Option columns share one width.
      expect(
        tester.getSize(recommended).width,
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text("5,800원/kg"),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .width,
      );
    });

    test("compare table refuses more than four options", () {
      expect(
        () => const LdsCompareTable(
          options: [
            LdsCompareOption("A"),
            LdsCompareOption("B"),
            LdsCompareOption("C"),
            LdsCompareOption("D"),
            LdsCompareOption("E"),
          ],
          rows: [],
        ).build(_FakeContext()),
        throwsAssertionError,
      );
    });
  });
}

Color? _fillOf(WidgetTester tester, Finder container) =>
    tester.widget<Container>(container).color;

class _FakeContext extends Fake implements BuildContext {}
