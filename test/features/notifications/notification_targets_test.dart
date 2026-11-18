import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/notifications/presentation/notification_bell.dart";
import "package:gyeonjwo_frontend/features/notifications/presentation/notifications_view_model.dart";

class _FakeNotifications extends NotificationsViewModel {
  @override
  Future<NotificationsState> build() async => NotificationsState(
    readBefore: DateTime.utc(2026),
    items: [
      AppNotification(
        id: "1",
        kind: AppNotificationKind.reviewReady,
        detail: "[깐마늘]",
        createdAt: DateTime.utc(2026, 11, 18, 9),
        caseId: "c-review",
      ),
      AppNotification(
        id: "2",
        kind: AppNotificationKind.needsAttention,
        detail: "[냉동 딸기]",
        createdAt: DateTime.utc(2026, 11, 18, 8),
        caseId: "c-task",
      ),
    ],
  );
}

Future<GoRouter> _pump(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        builder: (_, _) => const Scaffold(
          body: Align(alignment: Alignment.topRight, child: NotificationBell()),
        ),
      ),
      GoRoute(
        path: "/tasks/:id",
        builder: (_, state) =>
            Scaffold(body: Text("업무 ${state.pathParameters["id"]}")),
      ),
      GoRoute(
        path: "/tasks/:id/review",
        builder: (_, state) =>
            Scaffold(body: Text("검토 ${state.pathParameters["id"]}")),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsViewModelProvider.overrideWith(_FakeNotifications.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.notifications_none));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets("검토 카드 준비 알림은 그 검토 카드로 갑니다", (tester) async {
    await _pump(tester);
    await tester.tap(find.text("검토 카드가 준비됐어요"));
    await tester.pumpAndSettle();
    expect(find.text("검토 c-review"), findsOneWidget);
  });

  testWidgets("업무가 있는 다른 알림은 그 업무 상세로 갑니다", (tester) async {
    await _pump(tester);
    await tester.tap(find.text("확인이 필요해서 멈춘 업무가 있어요"));
    await tester.pumpAndSettle();
    expect(find.text("업무 c-task"), findsOneWidget);
  });
}
