import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";

part "send_settings_data_source.g.dart";

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

class SendSettingsApiException implements Exception {
  const SendSettingsApiException(
    this.statusCode,
    this.code,
    this.message, {
    this.unknownOutcome = false,
  });

  final int statusCode;
  final String code;
  final String message;

  /// 응답을 받지 못함. 서버가 저장했는지 알 수 없습니다.
  final bool unknownOutcome;
}

class ApiSendSettingsDataSource implements SendSettingsDataSource {
  const ApiSendSettingsDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final Future<String?> Function({bool forceRefresh}) _accessToken;

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

  /// 만료된 세션은 한 번 갱신해 같은 요청(같은 멱등 키)으로 다시 보냅니다.
  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function(Map<String, String> headers)
    request, {
    String? idempotencyKey,
  }) async {
    for (final forceRefresh in const [false, true]) {
      final token = await _accessToken(forceRefresh: forceRefresh);
      if (token == null) {
        throw const SendSettingsApiException(
          401,
          "AUTH_REQUIRED",
          "다시 로그인해 주세요.",
        );
      }
      try {
        final response = await request({
          "Authorization": "Bearer $token",
          "Idempotency-Key": ?idempotencyKey,
        });
        final body = response.data;
        if (body == null) {
          throw const SendSettingsApiException(
            502,
            "INVALID_RESPONSE",
            "서버 응답을 확인하지 못했어요.",
          );
        }
        return body;
      } on DioException catch (error) {
        if (error.response?.statusCode == 401 && !forceRefresh) continue;
        // DioException keeps request headers; never rethrow it.
        throw _toException(error);
      }
    }
    throw const SendSettingsApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
  }

  static SendSettingsApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const SendSettingsApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
        unknownOutcome: true,
      );
    }
    final data = response.data;
    final detail = data is Map<String, dynamic> ? data["error"] : null;
    final status = response.statusCode ?? 0;
    return SendSettingsApiException(
      status,
      detail is Map<String, dynamic>
          ? detail["code"] as String? ?? "HTTP_$status"
          : "HTTP_$status",
      detail is Map<String, dynamic>
          ? detail["message"] as String? ?? "요청을 처리하지 못했어요."
          : "요청을 처리하지 못했어요.",
    );
  }
}
