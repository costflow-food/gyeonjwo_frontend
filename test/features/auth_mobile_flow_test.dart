import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/data/auth_repository_impl.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_failure.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_repository.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";
import "package:gyeonjwo_frontend/features/auth/domain/google_provider_grant.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_layout.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_permissions_view.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/gmail_connection_view_model.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// The Android app keeps running across Google consent, unlike the web page.

class _Auth implements AuthRepository {
  _Auth({this.signedIn = true});

  final bool signedIn;
  final events = StreamController<AuthSession>.broadcast();
  GoogleProviderGrant? pending;
  final connected = <String>[];
  int fetched = 0;

  @override
  AuthSession currentSession() => signedIn
      ? const AuthSession(
          status: AuthSessionStatus.signedIn,
          email: "kim@example.invalid",
        )
      : const AuthSession.signedOut();

  @override
  Stream<AuthSession> watchSession() => events.stream;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  AuthFailure? takeRedirectFailure() => null;

  @override
  GoogleProviderGrant? pendingGoogleGrant() => pending;

  @override
  Future<GmailConnection> connectGmail(GoogleProviderGrant grant) async {
    connected.add(grant.accessToken);
    return const GmailConnection(
      status: GmailConnectionStatus.connected,
      canRead: true,
      canSend: true,
    );
  }

  @override
  Future<GmailConnection> fetchGmailConnection() async {
    fetched++;
    return const GmailConnection(
      status: GmailConnectionStatus.partial,
      canRead: true,
    );
  }
}

Future<GoRouter> _pumpPhone(
  WidgetTester tester,
  _Auth auth, {
  Object? extra,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget page(String name) => Scaffold(body: Text(name));
  final router = GoRouter(
    initialLocation: "/login/permissions",
    initialExtra: extra,
    routes: [
      GoRoute(path: "/", builder: (_, _) => page("queue")),
      GoRoute(path: "/login", builder: (_, _) => page("login")),
      GoRoute(path: "/account", builder: (_, _) => page("account")),
      GoRoute(
        path: "/login/permissions",
        builder: (_, _) => const AuthPermissionsView(),
      ),
      GoRoute(
        path: "/login/connection",
        builder: (_, _) => const AuthLayout(
          backPath: "/login/permissions",
          child: Text("connection"),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp.router(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  test(
    "a new Google grant for the same account is sent to the server",
    () async {
      final auth = _Auth();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        gmailConnectionViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      // Signed in earlier; the first grant was already accepted.
      await container.read(gmailConnectionViewModelProvider.future);
      expect(auth.fetched, 1);
      expect(auth.connected, isEmpty);

      // Consent again with the same account: the session compares equal.
      auth.pending = const GoogleProviderGrant(accessToken: "new-token");
      auth.events.add(auth.currentSession());
      await pumpEventQueue();
      final connection = await container.read(
        gmailConnectionViewModelProvider.future,
      );
      expect(auth.connected, ["new-token"]);
      expect(connection.canSend, isTrue);

      // A token refresh with the same grant must not send it again.
      auth.events.add(auth.currentSession());
      await pumpEventQueue();
      await container.read(gmailConnectionViewModelProvider.future);
      expect(auth.connected, ["new-token"]);
      expect(auth.fetched, 1);
    },
  );

  testWidgets("system back on the permissions screen returns to the opener", (
    tester,
  ) async {
    final router = await _pumpPhone(tester, _Auth(), extra: "/account");
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("account"), findsOneWidget);

    // Without a known opener a signed-in user lands on the work queue.
    router.go("/login/permissions");
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("queue"), findsOneWidget);

    // From the connection screen back leads to the permissions screen.
    router.go("/login/connection");
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("연결 전에 확인해 주세요"), findsOneWidget);
  });

  testWidgets("system back before sign-in returns to the login screen", (
    tester,
  ) async {
    await _pumpPhone(tester, _Auth(signedIn: false));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("login"), findsOneWidget);
  });

  testWidgets("returning from Google consent opens the connection screen", (
    tester,
  ) async {
    await _pumpPhone(tester, _Auth());
    final button = find.text("Google로 계속하기");
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text("connection"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
