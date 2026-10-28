import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/app/app_router.dart";
import "package:gyeonjwo_frontend/features/auth/data/account_connection_data_source.dart";
import "package:gyeonjwo_frontend/features/auth/data/auth_session_data_source.dart";
import "package:gyeonjwo_frontend/main.dart";

import "support/fake_auth.dart";

void main() {
  Future<void> showApp(
    WidgetTester tester, {
    required FakeAuthSessionDataSource session,
    required FakeAccountConnectionDataSource server,
  }) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionDataSourceProvider.overrideWithValue(session),
          accountConnectionDataSourceProvider.overrideWithValue(server),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("signed-out users are sent to login", (tester) async {
    await showApp(
      tester,
      session: FakeAuthSessionDataSource(),
      server: FakeAccountConnectionDataSource(),
    );
    appRouter.go("/");
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, "/login");
    expect(find.textContaining("화면 미리보기"), findsNothing);
  });

  testWidgets("redirect grant is sent and a send denial is shown", (
    tester,
  ) async {
    final server = FakeAccountConnectionDataSource()
      ..responses.add(
        () => connectionResponse("PARTIAL", read: true, send: false),
      );
    await showApp(
      tester,
      session: FakeAuthSessionDataSource(session: signedInSession()),
      server: server,
    );
    appRouter.go("/login");
    await tester.pumpAndSettle();

    expect(
      appRouter.routeInformationProvider.value.uri.path,
      "/login/connection",
    );
    expect(server.requests, hasLength(1));
    expect(find.text("메일 수신부터 시작할 수 있어요"), findsOneWidget);
    expect(find.text("업무 큐로 이동"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("unknown outcome offers retry with the same request", (
    tester,
  ) async {
    final server = FakeAccountConnectionDataSource()
      ..responses.add(() => throw unknownOutcome())
      ..responses.add(() => connectionResponse("CONNECTED"));
    await showApp(
      tester,
      session: FakeAuthSessionDataSource(session: signedInSession()),
      server: server,
    );
    appRouter.go("/login/connection");
    await tester.pumpAndSettle();
    expect(find.text("계정을 연결하지 못했어요"), findsOneWidget);

    await tester.tap(find.text("다시 시도하기"));
    await tester.pumpAndSettle();
    expect(find.text("Gmail 연결이 준비됐어요"), findsOneWidget);
    expect(
      server.requests[0]["idempotency_key"],
      server.requests[1]["idempotency_key"],
    );
  });

  testWidgets("read denial shows the work queue notice", (tester) async {
    final server = FakeAccountConnectionDataSource()
      ..current = connectionResponse("PARTIAL", read: false, send: true);
    await showApp(
      tester,
      session: FakeAuthSessionDataSource(
        session: signedInSession(providerToken: null),
      ),
      server: server,
    );
    appRouter.go("/");
    await tester.pumpAndSettle();
    expect(find.textContaining("Gmail 읽기 권한이 없어"), findsOneWidget);
  });
}
