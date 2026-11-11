import "dart:typed_data";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
import "../../auth/data/auth_session_data_source.dart";

part "work_queue_data_source.g.dart";

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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

class ApiWorkQueueDataSource implements WorkQueueDataSource {
  const ApiWorkQueueDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";
  static const _mails = "/api/v1/mail-messages";

  final Dio _dio;
  final ApiTokenReader _accessToken;

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

  /// 세션 갱신·429 대기·오류 변환은 [sendApiRequest]가 맡습니다.
  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) => sendApiRequest(_accessToken, request, idempotencyKey: idempotencyKey);
}
