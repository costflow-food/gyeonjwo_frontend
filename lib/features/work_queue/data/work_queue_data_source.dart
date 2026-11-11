import "dart:convert";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";

part "work_queue_data_source.g.dart";

@Riverpod(keepAlive: true)
WorkQueueDataSource workQueueDataSource(Ref ref) => ApiWorkQueueDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// API-01 `GET /work-cases`, API-02 `GET /work-cases/{case_id}`,
/// API-25 `GET /mail-messages/{mail_id}`,
/// API-04 `POST /work-cases/{case_id}/start`,
/// API-05 `POST /work-cases/{case_id}/accept-increase`,
/// API-07 `POST /work-cases/{case_id}/resume`,
/// API-11 `GET /work-cases/{case_id}/candidates`,
/// API-12 `PUT /work-cases/{case_id}/candidate-selection`,
/// API-26 `GET /mail-messages/{mail_id}/attachments/{attachment_id}/content`.
abstract interface class WorkQueueDataSource {
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
    int? limit,
  });

  Future<Map<String, dynamic>> fetchOriginalMail(String mailId);

  /// 첨부 원본 바이트. 서버는 Gmail에서 받아 그대로 넘겨주고 저장하지 않습니다.
  Future<Uint8List> fetchAttachmentContent(String mailId, String attachmentId);

  Future<Map<String, dynamic>> acceptIncrease(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, dynamic>> start(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  /// API-02 one case: stored state and actions, no mail body.
  Future<Map<String, dynamic>> fetchCase(String caseId);

  Future<Map<String, dynamic>> resume(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, dynamic>> fetchCandidates(String caseId);

  Future<Map<String, dynamic>> selectCandidates(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class WorkQueueApiException implements Exception {
  const WorkQueueApiException(
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

typedef AccessTokenReader = Future<String?> Function({bool forceRefresh});

class ApiWorkQueueDataSource implements WorkQueueDataSource {
  const ApiWorkQueueDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";
  static const _mails = "/api/v1/mail-messages";

  final Dio _dio;
  final AccessTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
    int? limit,
  }) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      _cases,
      queryParameters: {
        "status": ?status,
        if (query.isNotEmpty) "q": query,
        "cursor": ?cursor,
        "limit": ?limit,
      },
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> fetchOriginalMail(String mailId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_mails/$mailId",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Uint8List> fetchAttachmentContent(
    String mailId,
    String attachmentId,
  ) async {
    final bytes = await _send(
      (headers) => _dio.get<List<int>>(
        "$_mails/$mailId/attachments/$attachmentId/content",
        options: Options(headers: headers, responseType: ResponseType.bytes),
      ),
    );
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  @override
  Future<Map<String, dynamic>> acceptIncrease(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/accept-increase",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> start(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/start",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> fetchCase(String caseId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_cases/$caseId",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> resume(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/resume",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> fetchCandidates(String caseId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_cases/$caseId/candidates",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> selectCandidates(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.put<Map<String, dynamic>>(
      "$_cases/$caseId/candidate-selection",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  /// 만료된 세션은 한 번 갱신해 같은 요청(같은 멱등 키)으로 다시 보냅니다.
  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) async {
    for (final forceRefresh in const [false, true]) {
      final token = await _accessToken(forceRefresh: forceRefresh);
      if (token == null) {
        throw const WorkQueueApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
      }
      try {
        final response = await request({
          "Authorization": "Bearer $token",
          "Idempotency-Key": ?idempotencyKey,
        });
        final body = response.data;
        if (body == null) {
          throw const WorkQueueApiException(
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
    throw const WorkQueueApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
  }

  static WorkQueueApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const WorkQueueApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
        unknownOutcome: true,
      );
    }
    final body = _errorBody(response.data);
    final detail = body is Map<String, dynamic> ? body["error"] : null;
    final status = response.statusCode ?? 0;
    return WorkQueueApiException(
      status,
      detail is Map<String, dynamic>
          ? detail["code"] as String? ?? "HTTP_$status"
          : "HTTP_$status",
      detail is Map<String, dynamic>
          ? detail["message"] as String? ?? "요청을 처리하지 못했어요."
          : "요청을 처리하지 못했어요.",
    );
  }

  /// 첨부 요청은 바이트로 받으므로 오류 본문도 바이트로 옵니다.
  static Object? _errorBody(Object? data) {
    if (data is! List<int>) return data;
    try {
      return jsonDecode(utf8.decode(data));
    } on FormatException {
      return null;
    }
  }
}
