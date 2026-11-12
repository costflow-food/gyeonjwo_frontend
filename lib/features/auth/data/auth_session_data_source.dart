import "dart:async";

import "package:app_links/app_links.dart";
import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../shared/navigation/page_navigation.dart";

part "auth_session_data_source.g.dart";

const gmailScopes = [
  "https://www.googleapis.com/auth/gmail.readonly",
  "https://www.googleapis.com/auth/gmail.send",
];

/// Where Google sign-in returns on Android. Must match the intent filter in
/// AndroidManifest.xml and be allowed in Supabase Auth's redirect URLs.
final mobileAuthRedirect = Uri.parse("com.costflow.gyeonjwo://login-callback");

const _googleQueryParams = {
  // A refresh token lets the server keep receiving mail.
  "access_type": "offline",
  // Ask every time so Google issues a refresh token again on reconnect.
  "prompt": "consent",
};

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
AuthSessionDataSource authSessionDataSource(Ref ref) =>
    SupabaseAuthSessionDataSource(Supabase.instance.client.auth);

/// Session values as a JSON-like map, mirroring the other DataSources.
///
/// Keys: `email`, `access_token`, `provider_token`, `provider_refresh_token`.
/// Never log these maps.
abstract interface class AuthSessionDataSource {
  Map<String, dynamic>? currentSession();

  /// Access token for API calls. Refreshes first when the stored session has
  /// expired (e.g. right after the app reopens) or when [forceRefresh] is set.
  Future<String?> freshAccessToken({bool forceRefresh = false});

  Stream<Map<String, dynamic>?> watchSession();

  /// `error`, `error_code`, `error_description` from the OAuth redirect URL.
  Map<String, String> redirectError();

  /// On web the page navigates away and this never returns a result. In the
  /// app it waits for the sign-in callback and returns its error fields
  /// (empty on success; the session then arrives on [watchSession]).
  Future<Map<String, String>> signInWithGoogle();

  Future<void> signOut();
}

class SupabaseAuthSessionDataSource implements AuthSessionDataSource {
  const SupabaseAuthSessionDataSource(this._auth);

  final GoTrueClient _auth;

  /// The app's open wait for the sign-in callback; at most one.
  static StreamSubscription<Uri>? _callbackWait;

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
  Map<String, String> redirectError() => _errorFields(Uri.base);

  static Map<String, String> _errorFields(Uri uri) {
    final Map<String, String> parameters;
    try {
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
  Future<Map<String, String>> signInWithGoogle() async {
    if (!kIsWeb) return _signInWithGoogleInApp();
    final base = Uri.base;
    final redirectTo = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: base.path,
    ).toString();
    // Build the URL (and store the PKCE verifier) here, then move this tab
    // ourselves: signInWithOAuth opens it with window.open(..., "_self",
    // "noopener"), which recent Chrome ignores and the button never leaves.
    final response = await _auth.getOAuthSignInUrl(
      provider: OAuthProvider.google,
      redirectTo: redirectTo,
      scopes: gmailScopes.join(" "),
      queryParams: _googleQueryParams,
    );
    navigateCurrentPage(Uri.parse(response.url));
    return const {};
  }

  /// Opens Google in the browser and waits for [mobileAuthRedirect].
  /// supabase_flutter exchanges the code from the same link on its own.
  Future<Map<String, String>> _signInWithGoogleInApp() async {
    // Backing out of the browser leaves the previous wait open; drop it so
    // one callback is not reported once per attempt.
    await _callbackWait?.cancel();
    final callback = Completer<Uri>();
    final wait = AppLinks().uriLinkStream
        .where(
          (uri) =>
              uri.scheme == mobileAuthRedirect.scheme &&
              uri.host == mobileAuthRedirect.host,
        )
        .listen(null);
    wait.onData((uri) {
      wait.cancel();
      if (!callback.isCompleted) callback.complete(uri);
    });
    _callbackWait = wait;
    final launched = await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: mobileAuthRedirect.toString(),
      scopes: gmailScopes.join(" "),
      queryParams: _googleQueryParams,
    );
    if (!launched) {
      await wait.cancel();
      throw StateError("Could not open the sign-in page.");
    }
    return _errorFields(await callback.future);
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
