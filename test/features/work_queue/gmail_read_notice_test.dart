import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/gmail_read_notice.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";

void main() {
  testWidgets("read-denied is an LdsNotice whose button re-asks permission", (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (_, _) => const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24),
              child: GmailReadNotice(),
            ),
          ),
        ),
        GoRoute(
          path: "/login/permissions",
          builder: (_, _) => const Text("permissions"),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final notice = tester.widget<LdsNotice>(find.byType(LdsNotice));
    expect(notice.tone, LdsNoticeTone.warning);
    expect(notice.icon, Icons.mark_email_unread_outlined);
    expect(find.textContaining("메일 자동 수신이 꺼져 있습니다"), findsOneWidget);
    await tester.tap(find.widgetWithText(LdsButton, "권한 다시 선택하기"));
    await tester.pumpAndSettle();
    expect(find.text("permissions"), findsOneWidget);
  });
}
