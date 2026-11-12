import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_scroll_behavior.dart";

Widget _app({ScrollBehavior? behavior}) => MaterialApp(
  scrollBehavior: behavior,
  home: Scaffold(
    body: ListView(
      children: [for (var i = 0; i < 40; i++) ListTile(title: Text("줄 $i"))],
    ),
  ),
);

void main() {
  testWidgets("lists do not stretch past their edge on Android", (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // What Flutter does by default, so the test notices if that changes.
    await tester.pumpWidget(_app());
    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);

    await tester.pumpWidget(_app(behavior: const AppScrollBehavior()));
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    // Scrolling itself is untouched.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text("줄 0"), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
