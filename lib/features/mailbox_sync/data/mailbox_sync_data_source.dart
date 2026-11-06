import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/authorized_json_get.dart";
import "../../auth/data/auth_session_data_source.dart";

part "mailbox_sync_data_source.g.dart";

@Riverpod(keepAlive: true)
MailboxSyncDataSource mailboxSyncDataSource(Ref ref) =>
    ApiMailboxSyncDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-32 메일함 수신 상태. 조회만 하며 메일을 가져오게 하지 않습니다.
abstract interface class MailboxSyncDataSource {
  Future<Map<String, dynamic>> fetchSyncStatus();
}

class ApiMailboxSyncDataSource implements MailboxSyncDataSource {
  const ApiMailboxSyncDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final ApiTokenReader _accessToken;

  /// 08은 `/mailboxes/{mailbox_ref}/sync-status`지만 BE는 사용자당 메일함
  /// 하나를 기준으로 이 경로를 엽니다.
  @override
  Future<Map<String, dynamic>> fetchSyncStatus() => authorizedJsonGet(
    _dio,
    _accessToken,
    "/api/v1/mailboxes/google/sync-status",
  );
}

/// UI 미리보기용 고정 응답.
class PreviewMailboxSyncDataSource implements MailboxSyncDataSource {
  const PreviewMailboxSyncDataSource({this.failing = false});

  /// true면 수신 실패, false면 방금 읽은 정상 상태입니다.
  final bool failing;

  @override
  Future<Map<String, dynamic>> fetchSyncStatus() async => {
    "data": {
      "mailbox_ref": "preview-mailbox",
      "status": failing ? "ERROR" : "IDLE",
      "last_synced_at": DateTime.now()
          .toUtc()
          .subtract(Duration(minutes: failing ? 42 : 1))
          .toIso8601String(),
      "last_error": failing ? "GMAIL_SYNC_FAILED" : null,
    },
    "meta": {"request_id": "req-preview-sync-status"},
  };
}
