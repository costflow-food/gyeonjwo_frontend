import "dart:async";

import "package:gyeonjwo_frontend/features/auth/data/account_connection_data_source.dart";
import "package:gyeonjwo_frontend/features/auth/data/auth_session_data_source.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_failure.dart";

/// In-memory Supabase session used instead of a real OAuth redirect.
class FakeAuthSessionDataSource implements AuthSessionDataSource {
  FakeAuthSessionDataSource({this.session, this.error = const {}});

  Map<String, dynamic>? session;
  Map<String, String> error;
  int signInCalls = 0;
  final _changes = StreamController<Map<String, dynamic>?>.broadcast();

  void emit(Map<String, dynamic>? next) {
    session = next;
    _changes.add(next);
  }

  @override
  bool get isConfigured => true;

  @override
  Map<String, dynamic>? currentSession() => session;

  int refreshCalls = 0;

  @override
  Future<String?> freshAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) refreshCalls++;
    return session?["access_token"] as String?;
  }

  @override
  Stream<Map<String, dynamic>?> watchSession() => _changes.stream;

  @override
  Map<String, String> redirectError() => error;

  @override
  Future<void> signInWithGoogle() async {
    signInCalls++;
  }

  @override
  Future<void> signOut() async => emit(null);
}

/// Records connection requests; responses are queued per call.
class FakeAccountConnectionDataSource implements AccountConnectionDataSource {
  final requests = <Map<String, Object?>>[];
  final responses = <FutureOr<Map<String, dynamic>> Function()>[];
  Map<String, dynamic> current = connectionResponse("NOT_CONNECTED");

  @override
  Future<Map<String, dynamic>> connectGoogle({
    required String accessToken,
    required String providerAccessToken,
    required String? providerRefreshToken,
    required String idempotencyKey,
  }) async {
    requests.add({
      "access_token": accessToken,
      "provider_access_token": providerAccessToken,
      "provider_refresh_token": providerRefreshToken,
      "idempotency_key": idempotencyKey,
    });
    return responses.removeAt(0)();
  }

  @override
  Future<Map<String, dynamic>> fetchGoogleConnection({
    required String accessToken,
  }) async => current;
}

Map<String, dynamic> signedInSession({String? providerToken = "google-at"}) => {
  "email": "buyer@example.com",
  "access_token": "supabase-at",
  "provider_token": providerToken,
  "provider_refresh_token": providerToken == null ? null : "google-rt",
};

Map<String, dynamic> connectionResponse(
  String status, {
  bool read = true,
  bool send = true,
}) => {
  "data": {
    "mailbox_ref": "mailbox-1",
    "email": "buyer@example.com",
    "status": status,
    "capabilities": {"read": read, "send": send},
    "watch": {"started": read},
  },
  "meta": {"request_id": "req-test"},
};

AuthFailure unknownOutcome() =>
    const AuthFailure(AuthFailureCode.serverUnavailable, retryable: true);
