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

  /// Without Supabase settings the app keeps the existing preview behavior.
  static bool get isAuthConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
