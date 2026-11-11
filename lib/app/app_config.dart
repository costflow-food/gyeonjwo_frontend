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

  /// 배포 워크플로가 넣는 커밋 앞 7자리. 로컬 실행에서는 비어 있습니다.
  static const buildRevision = String.fromEnvironment("BUILD_REVISION");

  static List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) "SUPABASE_URL",
    if (supabasePublishableKey.isEmpty) "SUPABASE_PUBLISHABLE_KEY",
    if (apiBaseUrl.isEmpty) "API_BASE_URL",
  ];

  static bool get isConfigured => missingKeys.isEmpty;
}
