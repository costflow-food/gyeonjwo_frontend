import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
import "../../auth/data/auth_session_data_source.dart";

part "send_settings_data_source.g.dart";

/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
@Riverpod(keepAlive: true)
SendSettingsDataSource sendSettingsDataSource(Ref ref) =>
    ApiSendSettingsDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-21 `GET /mail-send-settings` and API-22 `PUT /mail-send-settings`.
abstract interface class SendSettingsDataSource {
  Future<Map<String, dynamic>> fetchSettings({String? caseId});

  Future<Map<String, dynamic>> saveSettings(
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class ApiSendSettingsDataSource implements SendSettingsDataSource {
  const ApiSendSettingsDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final ApiTokenReader _accessToken;

  /// Without mailbox_ref the server picks the case's or the sole mailbox;
  /// the response's mailbox_ref is what a save must send back.
  @override
  Future<Map<String, dynamic>> fetchSettings({String? caseId}) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "/api/v1/mail-send-settings",
      queryParameters: {"case_id": ?caseId},
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> saveSettings(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.put<Map<String, dynamic>>(
      "/api/v1/mail-send-settings",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  /// 세션 갱신·429 대기·오류 변환은 [sendApiRequest]가 맡습니다.
  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) => sendApiRequest(_accessToken, request, idempotencyKey: idempotencyKey);
}
