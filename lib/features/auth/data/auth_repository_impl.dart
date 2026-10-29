import "dart:math";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/auth_failure.dart";
import "../domain/auth_repository.dart";
import "../domain/auth_session.dart";
import "../domain/gmail_connection.dart";
import "../domain/google_provider_grant.dart";
import "account_connection_data_source.dart";
import "auth_session_data_source.dart";

part "auth_repository_impl.g.dart";

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  ref.watch(authSessionDataSourceProvider),
  ref.watch(accountConnectionDataSourceProvider),
);

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._session, this._connection, {Random? random})
    : _random = random ?? Random.secure();

  final AuthSessionDataSource _session;
  final AccountConnectionDataSource _connection;
  final Random _random;

  /// Provider token the server already accepted; never sent twice.
  String? _acceptedProviderToken;

  /// Reused only while the previous attempt's outcome is unknown.
  String? _pendingIdempotencyKey;
  bool _redirectFailureTaken = false;

  /// One request per grant even if the screen rebuilds while it is pending.
  ({String token, Future<GmailConnection> result})? _inFlight;

  @override
  AuthSession currentSession() => _toSession(_session.currentSession());

  @override
  Stream<AuthSession> watchSession() => _session.watchSession().map(_toSession);

  @override
  Future<void> signInWithGoogle() async {
    if (!_session.isConfigured) {
      throw const AuthFailure(AuthFailureCode.notConfigured);
    }
    await _session.signInWithGoogle();
  }

  @override
  Future<void> signOut() async {
    _acceptedProviderToken = null;
    _inFlight = null;
    _pendingIdempotencyKey = null;
    await _session.signOut();
  }

  @override
  AuthFailure? takeRedirectFailure() {
    if (_redirectFailureTaken) return null;
    _redirectFailureTaken = true;
    final error = _session.redirectError();
    if (error.isEmpty) return null;
    final cancelled =
        error["error"] == "access_denied" ||
        error["error_code"] == "access_denied";
    return AuthFailure(
      cancelled ? AuthFailureCode.oauthCancelled : AuthFailureCode.oauthFailed,
      serverCode: error["error_code"] ?? error["error"],
    );
  }

  @override
  GoogleProviderGrant? pendingGoogleGrant() {
    final session = _session.currentSession();
    final token = session?["provider_token"] as String?;
    if (token == null || token == _acceptedProviderToken) return null;
    return GoogleProviderGrant(
      accessToken: token,
      refreshToken: session!["provider_refresh_token"] as String?,
    );
  }

  @override
  Future<GmailConnection> connectGmail(GoogleProviderGrant grant) {
    final inFlight = _inFlight;
    if (inFlight != null && inFlight.token == grant.accessToken) {
      return inFlight.result;
    }
    late final Future<GmailConnection> result;
    result = _connectGmail(grant).whenComplete(() {
      if (identical(_inFlight?.result, result)) _inFlight = null;
    });
    _inFlight = (token: grant.accessToken, result: result);
    return result;
  }

  Future<GmailConnection> _connectGmail(GoogleProviderGrant grant) async {
    final key = _pendingIdempotencyKey ??= _newIdempotencyKey();
    try {
      final response = await _withSession(
        (accessToken) => _connection.connectGoogle(
          accessToken: accessToken,
          providerAccessToken: grant.accessToken,
          providerRefreshToken: grant.refreshToken,
          idempotencyKey: key,
        ),
      );
      _pendingIdempotencyKey = null;
      final connection = _toConnection(response);
      if (connection.status != GmailConnectionStatus.failed) {
        _acceptedProviderToken = grant.accessToken;
      }
      return connection;
    } on AuthFailure catch (failure) {
      // Same key only when the server may have processed the request.
      if (!failure.retryable) _pendingIdempotencyKey = null;
      rethrow;
    }
  }

  @override
  Future<GmailConnection> fetchGmailConnection() async {
    if (!currentSession().isSignedIn) {
      return const GmailConnection.notConnected();
    }
    final response = await _withSession(
      (accessToken) =>
          _connection.fetchGoogleConnection(accessToken: accessToken),
    );
    return _toConnection(response);
  }

  /// Calls the API with a fresh Supabase token. A stored session can be
  /// expired when the app reopens, so a 401 gets one refresh and retry.
  Future<T> _withSession<T>(Future<T> Function(String accessToken) call) async {
    try {
      return await call(await _accessToken());
    } on AuthFailure catch (failure) {
      if (failure.code != AuthFailureCode.sessionExpired) rethrow;
      return call(await _accessToken(forceRefresh: true));
    }
  }

  Future<String> _accessToken({bool forceRefresh = false}) async {
    final token = await _session.freshAccessToken(forceRefresh: forceRefresh);
    if (token == null) throw const AuthFailure(AuthFailureCode.sessionExpired);
    return token;
  }

  AuthSession _toSession(Map<String, dynamic>? json) {
    if (!_session.isConfigured) return const AuthSession.unconfigured();
    if (json == null) return const AuthSession.signedOut();
    return AuthSession(
      status: AuthSessionStatus.signedIn,
      email: json["email"] as String?,
    );
  }

  GmailConnection _toConnection(Map<String, dynamic> response) {
    final data = response["data"];
    if (data is! Map<String, dynamic>) {
      throw const AuthFailure(AuthFailureCode.serverUnavailable);
    }
    final capabilities = data["capabilities"];
    final watch = data["watch"];
    return GmailConnection(
      status: switch (data["status"]) {
        "CONNECTED" => GmailConnectionStatus.connected,
        "PARTIAL" => GmailConnectionStatus.partial,
        "NEEDS_RECONNECT" => GmailConnectionStatus.needsReconnect,
        "NOT_CONNECTED" => GmailConnectionStatus.notConnected,
        _ => GmailConnectionStatus.failed,
      },
      email: data["email"] as String?,
      canRead:
          capabilities is Map<String, dynamic> && capabilities["read"] == true,
      canSend:
          capabilities is Map<String, dynamic> && capabilities["send"] == true,
      watchStarted: watch is Map<String, dynamic> && watch["started"] == true,
    );
  }

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
  }
}
