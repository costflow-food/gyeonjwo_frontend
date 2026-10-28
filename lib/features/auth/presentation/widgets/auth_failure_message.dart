import "../../domain/auth_failure.dart";

extension AuthFailureMessage on AuthFailure {
  /// User-facing text. Never includes tokens or raw server responses.
  String get message => switch (code) {
    AuthFailureCode.notConfigured =>
      "견줘 연결 설정이 아직 준비되지 않았어요. 관리자에게 문의해 주세요.",
    AuthFailureCode.insecureServer =>
      "안전한 HTTPS 서버 주소가 아니어서 연결 정보를 보내지 않았어요.",
    AuthFailureCode.oauthCancelled =>
      "Google 로그인이 취소됐어요. 준비되면 다시 시작해 주세요.",
    AuthFailureCode.oauthFailed =>
      "Google 로그인 중 문제가 생겼어요. 다시 시도해 주세요.",
    AuthFailureCode.sessionExpired =>
      "로그인 세션이 만료됐어요. Google 계정을 다시 연결해 주세요.",
    AuthFailureCode.serverUnavailable =>
      "견줘 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.",
    AuthFailureCode.serverRejected =>
      "견줘 서버가 계정 연결을 완료하지 못했어요. Google 계정을 다시 연결해 주세요.",
  };
}
