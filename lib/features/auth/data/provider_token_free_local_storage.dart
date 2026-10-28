import "dart:convert";

import "package:supabase_flutter/supabase_flutter.dart";

/// Session storage that never writes Google provider tokens to the browser.
///
/// Supabase persists the whole session (including `provider_token` and
/// `provider_refresh_token`) to localStorage by default. The tokens are only
/// needed in memory until the server accepts them.
class ProviderTokenFreeLocalStorage extends LocalStorage {
  ProviderTokenFreeLocalStorage(this._delegate);

  /// Uses the same storage key as the default Supabase Flutter storage.
  factory ProviderTokenFreeLocalStorage.forSupabaseUrl(String supabaseUrl) =>
      ProviderTokenFreeLocalStorage(
        SharedPreferencesLocalStorage(
          persistSessionKey:
              "sb-${Uri.parse(supabaseUrl).host.split(".").first}-auth-token",
        ),
      );

  final LocalStorage _delegate;

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<bool> hasAccessToken() => _delegate.hasAccessToken();

  @override
  Future<String?> accessToken() async {
    final session = await _delegate.accessToken();
    return session == null ? null : stripProviderTokens(session);
  }

  @override
  Future<void> removePersistedSession() => _delegate.removePersistedSession();

  @override
  Future<void> persistSession(String persistSessionString) =>
      _delegate.persistSession(stripProviderTokens(persistSessionString));
}

String stripProviderTokens(String sessionJson) {
  final Object? decoded;
  try {
    decoded = jsonDecode(sessionJson);
  } on FormatException {
    return sessionJson;
  }
  if (decoded is! Map<String, dynamic>) return sessionJson;
  decoded
    ..remove("provider_token")
    ..remove("provider_refresh_token");
  return jsonEncode(decoded);
}
