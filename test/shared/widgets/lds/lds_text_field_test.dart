import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";

Future<void> _pump(WidgetTester tester, Widget field) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: field)),
    ),
  ),
);

OutlineInputBorder _border(WidgetTester tester, {bool focused = false}) {
  final decoration = tester
      .widget<TextField>(find.byType(TextField))
      .decoration!;
  return (focused ? decoration.focusedBorder : decoration.enabledBorder)!
      as OutlineInputBorder;
}

void main() {
  testWidgets("36 tall, #D1D6DC border radius 4, label above", (tester) async {
    await _pump(tester, const LdsTextField(label: "업체명", required: true));
    expect(tester.getSize(find.byType(TextField)).height, LdsTextField.height);
    final border = _border(tester);
    expect(border.borderSide.color, LdsColors.borderStrong);
    expect(border.borderRadius, BorderRadius.circular(4));
    expect(_border(tester, focused: true).borderSide.color, LdsColors.title);
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      greaterThan(tester.getBottomLeft(find.textContaining("업체명")).dy),
    );
  });

  testWidgets("an error turns the border red and says why below", (
    tester,
  ) async {
    await _pump(
      tester,
      const LdsTextField(label: "업체명", errorText: "업체명을 입력해 주세요."),
    );
    expect(_border(tester).borderSide.color, LdsColors.error);
    final error = tester.widget<Text>(find.text("업체명을 입력해 주세요."));
    expect(error.style!.color, LdsColors.error);
    expect(
      tester.getTopLeft(find.text("업체명을 입력해 주세요.")).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets("form field: validate shows the error, typing re-checks", (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      Form(
        key: form,
        child: LdsTextFormField(
          controller: controller,
          label: "업체명",
          required: true,
          validator: (value) =>
              (value ?? "").trim().isEmpty ? "업체명을 입력해 주세요." : null,
        ),
      ),
    );
    expect(find.text("업체명을 입력해 주세요."), findsNothing);
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text("업체명을 입력해 주세요."), findsOneWidget);
    expect(_border(tester).borderSide.color, LdsColors.error);
    await tester.enterText(find.byType(TextField), "한빛농산");
    await tester.pump();
    expect(find.text("업체명을 입력해 주세요."), findsNothing);
    expect(form.currentState!.validate(), isTrue);
  });
}
