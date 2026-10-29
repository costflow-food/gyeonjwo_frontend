import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../app/app_config.dart";

part "auth_session_data_source.g.dart";

/// Gmail scopes requested in the same Google consent as sign-in.
const gmailScopes = [
  "https://www.googleapis.com/auth/gmail.readonly",
  "https://www.googleapis.com/auth/gmail.send",
];

/// Google tokens that came back with this page's OAuth redirect.
///
/// After [Supabase.initialize] exchanges the redirect code it restores the
/// stored session in the background. The stored copy has no provider tokens
/// (see `ProviderTokenFreeLocalStorage`), so it can replace the fresh session
/// before the connection screen reads it. The auth stream replays the
/// original sign-in event, so the tokens are captured from it. Memory only.
abstract final class OAuthRedirectGrant {
  static ({String userId, String token, String? refreshToken})? _grant;
  static StreamSubscription<AuthState>? _subscription;

  /// Call once in main() right after [Supabase.initialize].
  static Future<void> captureFrom(GoTrueClient auth) async {
    _capture(auth.currentSession);
    _subscription ??= auth.onAuthStateChange.listen(
      (state) => _capture(state.session),
      onError: (Object _) {},
    );
    // Let the replayed events arrive before the first screen builds.
    await Future<void>.delayed(Duration.zero);
  }

  static void clear() => _grant = null;

  static void _capture(Session? session) {
    final token = session?.providerToken;
    if (session == null || token == null) return;
    _grant = (
      userId: session.user.id,
      token: token,
      refreshToken: session.providerRefreshToken,
    );
  }
}

@Riverpod(keepAlive: true)
AuthSessionDataSource authSessionDataSource(Ref ref) {
  // main() initializes Supabase before runApp whenever the settings exist.
  if (!AppConfig.isAuthConfigured) {
    return const UnconfiguredAuthSessionDataSource();
  }
  return SupabaseAuthSessionDataSource(Supabase.instance.client.auth);
}

/// Session values as a JSON-like map, mirroring the other DataSources.
///
/// Keys: `email`, `access_token`, `provider_token`, `provider_refresh_token`.
/// Never log these maps.
abstract interface class AuthSessionDataSource {
  bool get isConfigured;

  Map<String, dynamic>? currentSession();

  /// Access token for API calls. Refreshes first when the stored session has
  /// expired (e.g. right after the app reopens) or when [forceRefresh] is set.
  Future<String?> freshAccessToken({bool forceRefresh = false});

  Stream<Map<String, dynamic>?> watchSession();

  /// `error`, `error_code`, `error_description` from the OAuth redirect URL.
  Map<String, String> redirectError();

  Future<void> signInWithGoogle();

  Future<void> signOut();
}

class SupabaseAuthSessionDataSource implements AuthSessionDataSource {
  const SupabaseAuthSessionDataSource(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isConfigured => true;

  @override
  Map<String, dynamic>? currentSession() => _toJson(_auth.currentSession);

  @override
  Future<String?> freshAccessToken({bool forceRefresh = false}) async {
    final session = _auth.currentSession;
    if (session == null) return null;
    if (!forceRefresh && !session.isExpired) return session.accessToken;
    try {
      final response = await _auth.refreshSession();
      return response.session?.accessToken;
    } on AuthException {
      return null;
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchSession() => _auth.onAuthStateChange
      .map((state) => _toJson(state.session))
      // OAuth errors are read from the redirect URL instead.
      .handleError((Object _) {});

  @override
  Map<String, String> redirectError() {
    final Map<String, String> parameters;
    try {
      final uri = Uri.base;
      final fragment = uri.fragment.contains("?")
          ? uri.fragment.substring(uri.fragment.indexOf("?") + 1)
          : uri.fragment;
      parameters = {...Uri.splitQueryString(fragment), ...uri.queryParameters};
    } on FormatException {
      return const {};
    }
    return {
      for (final key in const ["error", "error_code", "error_description"])
        key: ?parameters[key],
    };
  }

  @override
  Future<void> signInWithGoogle() async {
    final base = Uri.base;
    // Return to the app root; the route guard opens the connection screen.
    final redirectTo = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: base.path,
    ).toString();
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      scopes: gmailScopes.join(" "),
      queryParams: const {
        // A refresh token lets the server keep receiving mail.
        "access_type": "offline",
        // Ask every time so Google issues a refresh token again on reconnect.
        "prompt": "consent",
      },
    );
  }

  @override
  Future<void> signOut() {
    OAuthRedirectGrant.clear();
    return _auth.signOut();
  }

  Map<String, dynamic>? _toJson(Session? session) {
    if (session == null) return null;
    var providerToken = session.providerToken;
    var providerRefreshToken = session.providerRefreshToken;
    final captured = OAuthRedirectGrant._grant;
    if (providerToken == null &&
        captured != null &&
        captured.userId == session.user.id) {
      providerToken = captured.token;
      providerRefreshToken = captured.refreshToken;
    }
    return {
      "email": session.user.email,
      "access_token": session.accessToken,
      "provider_token": providerToken,
      "provider_refresh_token": providerRefreshToken,
    };
  }
}

/// Used when Supabase settings are absent (UI preview and widget tests).
class UnconfiguredAuthSessionDataSource implements AuthSessionDataSource {
  const UnconfiguredAuthSessionDataSource();

  @override
  bool get isConfigured => false;

  @override
  Map<String, dynamic>? currentSession() => null;

  @override
  Future<String?> freshAccessToken({bool forceRefresh = false}) async => null;

  @override
  Stream<Map<String, dynamic>?> watchSession() => const Stream.empty();

  @override
  Map<String, String> redirectError() => const {};

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}
