import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/auth/data/auth_repository_impl.dart";
import "package:gyeonjwo_frontend/features/auth/data/auth_session_data_source.dart";
import "package:gyeonjwo_frontend/features/auth/data/provider_token_free_local_storage.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_failure.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_route_policy.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";

import "support/fake_auth.dart";

void main() {
  late FakeAuthSessionDataSource session;
  late FakeAccountConnectionDataSource server;
  late AuthRepositoryImpl repository;

  setUp(() {
    session = FakeAuthSessionDataSource(session: signedInSession());
    server = FakeAccountConnectionDataSource();
    repository = AuthRepositoryImpl(session, server);
  });

  test("sends the redirect grant once with the Supabase bearer token", () async {
    server.responses.add(() => connectionResponse("CONNECTED"));
    final grant = repository.pendingGoogleGrant()!;
    final connection = await repository.connectGmail(grant);

    expect(connection.phase, GmailConnectionPhase.connected);
    expect(server.requests.single["access_token"], "supabase-at");
    expect(server.requests.single["provider_refresh_token"], "google-rt");
    expect(repository.pendingGoogleGrant(), isNull);
    expect(grant.toString(), isNot(contains("google-at")));
  });

  test("concurrent screens share one in-flight connect request", () async {
    server.responses.add(() => connectionResponse("CONNECTED"));
    final grant = repository.pendingGoogleGrant()!;
    await Future.wait([
      repository.connectGmail(grant),
      repository.connectGmail(grant),
    ]);
    expect(server.requests, hasLength(1));
  });

  test("keeps the idempotency key only while the outcome is unknown", () async {
    server.responses
      ..add(() => throw unknownOutcome())
      ..add(() => throw const AuthFailure(AuthFailureCode.serverRejected))
      ..add(() => connectionResponse("CONNECTED"));
    final grant = repository.pendingGoogleGrant()!;

    await expectLater(repository.connectGmail(grant), throwsA(isA<AuthFailure>()));
    await expectLater(repository.connectGmail(grant), throwsA(isA<AuthFailure>()));
    await repository.connectGmail(grant);

    final keys = [for (final r in server.requests) r["idempotency_key"]];
    expect(keys[0], keys[1]);
    expect(keys[2], isNot(keys[1]));
  });

  test("partial grants map to read or send denial", () async {
    final cases = {
      (false, true): GmailConnectionPhase.readDenied,
      (true, false): GmailConnectionPhase.sendDenied,
      (false, false): GmailConnectionPhase.bothDenied,
    };
    for (final MapEntry(key: (read, send), value: phase) in cases.entries) {
      session.session = signedInSession(providerToken: "token-$read-$send");
      server.responses.add(
        () => connectionResponse("PARTIAL", read: read, send: send),
      );
      final connection = await repository.connectGmail(
        repository.pendingGoogleGrant()!,
      );
      expect(connection.phase, phase);
    }
  });

  test("a FAILED result leaves the grant available for retry", () async {
    server.responses.add(() => connectionResponse("FAILED", read: false));
    final grant = repository.pendingGoogleGrant()!;
    final connection = await repository.connectGmail(grant);
    expect(connection.phase, GmailConnectionPhase.failed);
    expect(repository.pendingGoogleGrant(), isNotNull);
  });

  test("without a fresh grant the server state is read", () async {
    session.session = signedInSession(providerToken: null);
    server.current = connectionResponse("NEEDS_RECONNECT", read: false);
    expect(repository.pendingGoogleGrant(), isNull);
    final connection = await repository.fetchGmailConnection();
    expect(connection.phase, GmailConnectionPhase.reconnect);
  });

  test("redirect errors are reported once", () {
    session.error = {"error": "access_denied"};
    expect(repository.takeRedirectFailure()?.code, AuthFailureCode.oauthCancelled);
    expect(repository.takeRedirectFailure(), isNull);
  });

  test("unconfigured data source keeps the preview mode", () async {
    final preview = AuthRepositoryImpl(
      const UnconfiguredAuthSessionDataSource(),
      server,
    );
    expect(preview.currentSession().status, AuthSessionStatus.unconfigured);
    await expectLater(preview.signInWithGoogle(), throwsA(isA<AuthFailure>()));
  });

  test("route guard allows consent guidance before sign-in", () {
    expect(authRedirect(AuthSessionStatus.signedOut, "/"), "/login");
    expect(authRedirect(AuthSessionStatus.signedOut, "/login/permissions"), isNull);
    expect(authRedirect(AuthSessionStatus.signedOut, "/login/connection"), "/login");
    expect(authRedirect(AuthSessionStatus.signedIn, "/login"), "/login/connection");
    expect(authRedirect(AuthSessionStatus.signedIn, "/account"), isNull);
    expect(authRedirect(AuthSessionStatus.unconfigured, "/"), isNull);
  });

  test("persisted sessions never contain Google provider tokens", () {
    const stored =
        '{"access_token":"a","provider_token":"g","provider_refresh_token":"r","user":{}}';
    final stripped = stripProviderTokens(stored);
    expect(stripped, isNot(contains("provider_token")));
    expect(stripped, contains('"access_token":"a"'));
  });
}
