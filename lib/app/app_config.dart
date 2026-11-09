/// Build-time settings passed with `--dart-define-from-file`.
///
/// Only public values belong here. Server secrets, Google client secrets and
/// OAuth tokens must never be compiled into the web bundle.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment("SUPABASE_URL");
  static const supabasePublishableKey = String.fromEnvironment(
    "SUPABASE_PUBLISHABLE_KEY",
  );
  static const apiBaseUrl = String.fromEnvironment("API_BASE_URL");

  /// Values the app cannot run without.
  static List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) "SUPABASE_URL",
    if (supabasePublishableKey.isEmpty) "SUPABASE_PUBLISHABLE_KEY",
    if (apiBaseUrl.isEmpty) "API_BASE_URL",
  ];

  static bool get isConfigured => missingKeys.isEmpty;
}
