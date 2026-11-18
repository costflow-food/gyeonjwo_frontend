import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/app/app_router.dart";
import "package:gyeonjwo_frontend/app/app_paths.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_route_policy.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";

void main() {
  group("legacy /cases addresses (KAN-321)", () {
    test("a case opens under /tasks", () {
      expect(legacyCaseRedirect(Uri.parse("/cases/x")), "/tasks/x");
    });

    test("its review card too, keeping the query", () {
      expect(
        legacyCaseRedirect(Uri.parse("/cases/x/review")),
        "/tasks/x/review",
      );
      expect(
        legacyCaseRedirect(Uri.parse("/cases/x?tab=confirm")),
        "/tasks/x?tab=confirm",
      );
    });

    test("other addresses are left alone", () {
      expect(legacyCaseRedirect(Uri.parse("/tasks/x")), isNull);
      expect(legacyCaseRedirect(Uri.parse("/cases")), isNull);
    });
  });

  test("new paths", () {
    expect(AppPaths.task("x"), "/tasks/x");
    expect(AppPaths.review("x"), "/tasks/x/review");
  });

  test("a connected Gmail lands on the Dashboard", () {
    expect(
      authRedirect(
        AuthSessionStatus.signedIn,
        "/login/connection",
        gmailReady: true,
      ),
      AppPaths.dashboard,
    );
  });

  testWidgets("the router sends /cases links to /tasks", (tester) async {
    Widget page(GoRouterState state) => Text(state.uri.toString());
    final router = GoRouter(
      initialLocation: "/cases/a",
      routes: [
        GoRoute(path: "/tasks/:caseId", builder: (_, state) => page(state)),
        GoRoute(
          path: "/tasks/:caseId/review",
          builder: (_, state) => page(state),
        ),
        legacyCaseRoute,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text("/tasks/a"), findsOneWidget);

    router.go("/cases/b/review");
    await tester.pumpAndSettle();
    expect(find.text("/tasks/b/review"), findsOneWidget);
  });
}
