import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../app/app_config.dart";

part "auth_session_data_source.g.dart";

/// Gmail scopes requested in the same Google consent as sign-in.
const gmailScopes = [
  "https://www.googleapis.com/auth/gmail.readonly",
  "https://www.googleapis.com/auth/gmail.send",
];

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
  Future<void> signOut() => _auth.signOut();

  Map<String, dynamic>? _toJson(Session? session) => session == null
      ? null
      : {
          "email": session.user.email,
          "access_token": session.accessToken,
          "provider_token": session.providerToken,
          "provider_refresh_token": session.providerRefreshToken,
        };
}

/// Used when Supabase settings are absent (UI preview and widget tests).
class UnconfiguredAuthSessionDataSource implements AuthSessionDataSource {
  const UnconfiguredAuthSessionDataSource();

  @override
  bool get isConfigured => false;

  @override
  Map<String, dynamic>? currentSession() => null;

  @override
  Stream<Map<String, dynamic>?> watchSession() => const Stream.empty();

  @override
  Map<String, String> redirectError() => const {};

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}
