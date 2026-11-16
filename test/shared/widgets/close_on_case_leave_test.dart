import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/shared/widgets/close_on_case_leave.dart";

/// Same shape as the app router: one route for every case, so switching cases
/// keeps the page (and any dialog on top of it) unless something closes it.
GoRouter _router() => GoRouter(
  initialLocation: "/cases/a",
  routes: [
    GoRoute(
      path: "/cases/:caseId",
      builder: (context, state) =>
          _CasePage(caseId: state.pathParameters["caseId"]!),
    ),
    GoRoute(
      path: "/cases/:caseId/review",
      builder: (context, state) => const Scaffold(body: Text("검토 카드")),
    ),
  ],
);

bool _keepOpen = false;

class _CasePage extends StatelessWidget {
  const _CasePage({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () {
        final router = GoRouter.of(context);
        showDialog<void>(
          context: context,
          builder: (_) => CloseOnCaseLeave(
            router: router,
            caseId: caseId,
            keepOpen: () => _keepOpen,
            child: const Dialog(child: Text("업무 창")),
          ),
        );
      },
      child: Text("열기 $caseId"),
    ),
  );
}

void main() {
  setUp(() => _keepOpen = false);

  Future<GoRouter> openWindow(WidgetTester tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text("열기 a"));
    await tester.pumpAndSettle();
    expect(find.text("업무 창"), findsOneWidget);
    return router;
  }

  testWidgets("moving to another case closes the window", (tester) async {
    final router = await openWindow(tester);
    router.go("/cases/b");
    await tester.pumpAndSettle();
    expect(find.text("업무 창"), findsNothing);
    expect(find.text("열기 b"), findsOneWidget);
  });

  testWidgets("unsaved edits keep the window open", (tester) async {
    final router = await openWindow(tester);
    _keepOpen = true;
    router.go("/cases/b");
    await tester.pumpAndSettle();
    expect(find.text("업무 창"), findsOneWidget);
  });

  test("the case's own pages do not count as leaving", () {
    expect(leavesCase("/cases/a", caseId: "a"), isFalse);
    expect(leavesCase("/cases/a/review", caseId: "a"), isFalse);
    expect(leavesCase("/", caseId: "a", openedAt: "/"), isFalse);
    expect(leavesCase("/cases/b", caseId: "a", openedAt: "/cases/a"), isTrue);
    expect(leavesCase("/cases/ab", caseId: "a"), isTrue);
    expect(leavesCase("/logs", caseId: "a", openedAt: "/cases/a"), isTrue);
  });
}
