import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_layout.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/widgets/google_sign_in_button.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

Future<void> _pump(WidgetTester tester, Widget child) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: Center(child: SizedBox(width: 480, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets("auth button is LDS large: 48 tall, corners 6, arrow after", (
    tester,
  ) async {
    await _pump(tester, AuthButton(label: "Google로 계속하기", onPressed: () {}));
    final button = tester.widget<LdsButton>(find.byType(LdsButton));
    expect(button.size, LdsButtonSize.large);
    expect(button.trailingIcon, Icons.arrow_forward);
    expect(tester.getSize(find.byType(LdsButton)).height, 48);
    expect(tester.getSize(find.byType(LdsButton)).width, 480);
    // The arrow follows the label.
    expect(
      tester.getCenter(find.byIcon(Icons.arrow_forward)).dx,
      greaterThan(tester.getCenter(find.text("Google로 계속하기")).dx),
    );
  });

  testWidgets("Google button keeps its brand look at 48 tall, corners 6", (
    tester,
  ) async {
    await _pump(tester, GoogleSignInButton(onPressed: () {}));
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final shape = button.style!.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(6));
    expect(button.style!.backgroundColor!.resolve({}), Colors.white);
    expect(tester.getSize(find.byType(OutlinedButton)).height, 48);
  });

  testWidgets("auth card: white, 1px line, no shadow; step is plain text", (
    tester,
  ) async {
    await _pump(
      tester,
      const AuthCard(
        child: AuthHeading(step: "01 / 시작하기", title: "제목", description: "설명"),
      ),
    );
    final decoration =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(AuthCard),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, Border.all(color: LdsColors.line));
    final step = tester.widget<Text>(find.text("01 / 시작하기"));
    expect(step.style!.color, LdsColors.primaryHover);
    expect(step.style!.fontWeight, FontWeight.w700);
  });
}
