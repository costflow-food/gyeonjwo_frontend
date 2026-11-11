import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/app/not_found_view.dart";
import "package:gyeonjwo_frontend/shared/widgets/brand_logo.dart";

void main() {
  testWidgets("an unknown address shows the app's own page and leads home", (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: "/no-such-page",
      errorBuilder: (context, state) => const NotFoundView(),
      routes: [
        GoRoute(path: "/", builder: (context, state) => const Text("업무 큐")),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text("페이지를 찾을 수 없습니다"), findsOneWidget);
    final screenCenter = tester.getCenter(find.byType(NotFoundView)).dx;
    final logoCenter = tester.getCenter(find.byType(BrandLogo)).dx;
    expect(logoCenter, closeTo(screenCenter, 1));
    expect(find.textContaining("GoException"), findsNothing);

    await tester.tap(find.text("업무 큐로 이동"));
    await tester.pumpAndSettle();
    expect(find.text("업무 큐"), findsOneWidget);
  });
}
