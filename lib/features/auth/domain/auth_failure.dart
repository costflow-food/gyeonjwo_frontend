enum AuthFailureCode {
  notConfigured,

  insecureServer,

  oauthCancelled,

  oauthFailed,

  sessionExpired,

  serverUnavailable,

  serverRejected,
}

/// Failure that is safe to show and log: it never carries tokens or bodies.
class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.serverCode, this.retryable = false});

  final AuthFailureCode code;

  final String? serverCode;

  final bool retryable;

  @override
  String toString() => "AuthFailure(${code.name}, ${serverCode ?? "-"})";
}
