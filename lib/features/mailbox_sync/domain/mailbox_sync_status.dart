/// API-32 메일함 수신 상태. 토큰·커서 같은 값은 서버가 주지 않습니다.
class MailboxSyncStatus {
  const MailboxSyncStatus({
    required this.status,
    this.lastSyncedAt,
    this.lastError,
  });

  /// `data`. 연결된 메일함이 없으면 status가 NOT_CONNECTED입니다.
  factory MailboxSyncStatus.fromJson(Map<String, dynamic> json) =>
      MailboxSyncStatus(
        status: json["status"] as String? ?? "",
        lastSyncedAt: DateTime.tryParse(
          json["last_synced_at"] as String? ?? "",
        ),
        lastError: json["last_error"] as String?,
      );

  /// 마지막으로 메일함을 읽은 지 이보다 오래되면 수신이 늦어진 것으로 봅니다.
  /// 서버는 1분마다 읽으므로 여러 번 연달아 못 읽은 경우입니다.
  static const staleAfter = Duration(minutes: 15);

  /// IDLE·RUNNING·ERROR, 연결이 없으면 NOT_CONNECTED.
  final String status;
  final DateTime? lastSyncedAt;

  /// 짧은 오류 코드. 화면 문구로 쓰지 않습니다.
  final String? lastError;

  bool get connected => status != "NOT_CONNECTED";

  /// 서버가 수신 실패를 기록함.
  bool get failed => connected && (status == "ERROR" || lastError != null);

  /// 실패 기록은 없지만 한동안 메일함을 읽지 못함. 서버가 실패를 기록하지
  /// 않는 경우(S1-2)에도 수신이 멈춘 것을 알 수 있습니다.
  bool isStale(DateTime now) =>
      connected &&
      !failed &&
      lastSyncedAt != null &&
      now.difference(lastSyncedAt!) > staleAfter;

  @override
  bool operator ==(Object other) =>
      other is MailboxSyncStatus &&
      other.status == status &&
      other.lastSyncedAt == lastSyncedAt &&
      other.lastError == lastError;

  @override
  int get hashCode => Object.hash(status, lastSyncedAt, lastError);
}
