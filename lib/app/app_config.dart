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

  /// 운영(PRD) Supabase 프로젝트 ref. 이 DB를 가리키면 로그인 생략은 켜지지 않습니다.
  static const productionSupabaseRef = "qlabhitzpdiawtbdmlgw";

  /// DEV 존 전용 로그인 생략. DEV 배포 워크플로만 `AUTH_DISABLED=true`로 빌드합니다.
  static const _authDisabled = bool.fromEnvironment("AUTH_DISABLED");

  /// 로그인 화면 없이 바로 메인으로 엽니다. 서버(DEV)도 `DEV_NO_AUTH_USER_ID`로
  /// 같은 고정 사용자를 씁니다. 운영 Supabase를 가리키면 값과 무관하게 꺼집니다.
  static bool get loginDisabled =>
      _authDisabled && !supabaseUrl.contains(productionSupabaseRef);

  static List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) "SUPABASE_URL",
    if (supabasePublishableKey.isEmpty) "SUPABASE_PUBLISHABLE_KEY",
    if (apiBaseUrl.isEmpty) "API_BASE_URL",
  ];

  static bool get isConfigured => missingKeys.isEmpty;
}
