enum AuthFailureCode {
  /// Supabase or the API server address is missing from the build settings.
  notConfigured,

  /// The API server address is not HTTPS (localhost is allowed for development).
  insecureServer,

  /// The user cancelled the Google account or consent screen.
  oauthCancelled,

  /// Google or Supabase returned an error on the OAuth redirect.
  oauthFailed,

  /// The Supabase session is missing or the server rejected it.
  sessionExpired,

  /// The server could not be reached or failed temporarily.
  serverUnavailable,

  /// The server answered and refused the request.
  serverRejected,
}

/// Failure that is safe to show and log: it never carries tokens or bodies.
class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.serverCode, this.retryable = false});

  final AuthFailureCode code;

  /// The `error.code` value from the API error response, if any.
  final String? serverCode;

  /// Whether the same request may be retried with the same idempotency key.
  final bool retryable;

  @override
  String toString() => "AuthFailure(${code.name}, ${serverCode ?? "-"})";
}
