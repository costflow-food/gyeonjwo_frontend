/// 서버가 지금 검토 실행과 메일 발송을 할 수 있는지.
///
/// `null`은 확인하지 못했다는 뜻입니다. 모르는 상태로는 배너를 띄우지 않습니다.
class ServerStatus {
  const ServerStatus({this.reviewReady, this.mailSendingEnabled});

  /// `/ready`: 503(준비 안 됨)이거나 `degraded_features`에 review가 있으면 false.
  final bool? reviewReady;

  /// `/health.mail_sending_enabled`.
  final bool? mailSendingEnabled;

  bool get showReviewBanner => reviewReady == false;
  bool get showMailSendingBanner => mailSendingEnabled == false;

  @override
  bool operator ==(Object other) =>
      other is ServerStatus &&
      other.reviewReady == reviewReady &&
      other.mailSendingEnabled == mailSendingEnabled;

  @override
  int get hashCode => Object.hash(reviewReady, mailSendingEnabled);
}
