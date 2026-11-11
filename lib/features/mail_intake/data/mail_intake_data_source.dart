import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";

part "mail_intake_data_source.g.dart";

@Riverpod(keepAlive: true)
MailIntakeDataSource mailIntakeDataSource(Ref ref) => ApiMailIntakeDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// API-23 `GET /mail-intake`, API-24 `POST /mail-messages/{mail_id}/resolve`.
abstract interface class MailIntakeDataSource {
  Future<Map<String, dynamic>> fetchPending({String? cursor, int limit = 25});

  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class MailIntakeApiException implements Exception {
  const MailIntakeApiException(
    this.statusCode,
    this.code,
    this.message, {
    this.unknownOutcome = false,
  });

  final int statusCode;
  final String code;
  final String message;

  /// 응답을 받지 못함. 서버가 처리했는지 알 수 없습니다.
  final bool unknownOutcome;
}

class ApiMailIntakeDataSource implements MailIntakeDataSource {
  const ApiMailIntakeDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final Future<String?> Function({bool forceRefresh}) _accessToken;

  @override
  Future<Map<String, dynamic>> fetchPending({
    String? cursor,
    int limit = 25,
  }) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "/api/v1/mail-intake",
      queryParameters: {"limit": limit, "cursor": ?cursor},
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "/api/v1/mail-messages/$mailId/resolve",
      // The server rejects unknown fields; null optionals are omitted.
      data: {
        for (final entry in body.entries)
          if (entry.value != null) entry.key: entry.value,
      },
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
        throw const MailIntakeApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
      }
      try {
        final response = await request({
          "Authorization": "Bearer $token",
          "Idempotency-Key": ?idempotencyKey,
        });
        final body = response.data;
        if (body == null) {
          throw const MailIntakeApiException(
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
    throw const MailIntakeApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
  }

  static MailIntakeApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const MailIntakeApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
        unknownOutcome: true,
      );
    }
    final data = response.data;
    final detail = data is Map<String, dynamic> ? data["error"] : null;
    final status = response.statusCode ?? 0;
    return MailIntakeApiException(
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
