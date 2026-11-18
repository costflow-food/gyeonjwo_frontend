import "auth_session_data_source.dart";

/// DEV 존(로그인 생략) 세션. 항상 로그인된 고정 DEV 사용자입니다.
///
/// DEV 서버는 `DEV_NO_AUTH_USER_ID`가 있으면 토큰을 보지 않고 같은 사용자로
/// 처리합니다. 운영 빌드에서는 쓰이지 않습니다(`AppConfig.loginDisabled`).
class DevNoLoginSessionDataSource implements AuthSessionDataSource {
  const DevNoLoginSessionDataSource();

  static const email = "dev@thoner.local";

  /// 서버는 값을 보지 않지만 요청 형식(`Authorization: Bearer`)을 맞추려고 보냅니다.
  static const token = "dev-no-login";

  static Map<String, dynamic> _session() => <String, dynamic>{
    "email": email,
    "access_token": token,
  };

  @override
  Map<String, dynamic>? currentSession() => _session();

  @override
  Future<String?> freshAccessToken({bool forceRefresh = false}) async => token;

  @override
  Stream<Map<String, dynamic>?> watchSession() => Stream.value(_session());

  @override
  Map<String, String> redirectError() => const {};

  @override
  Future<Map<String, String>> signInWithGoogle() async => const {};

  @override
  Future<void> signOut() async {}
}
