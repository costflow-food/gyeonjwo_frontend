import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";

part "mail_draft_data_source.g.dart";

@Riverpod(keepAlive: true)
MailDraftDataSource mailDraftDataSource(Ref ref) => ApiMailDraftDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// API-16 `GET /work-cases/{case_id}/mail-drafts`,
/// API-17 `GET /mail-drafts/{draft_id}`,
/// API-18 `POST /mail-drafts/{draft_id}/revisions`,
/// API-19 `POST /mail-drafts/{draft_id}/approve-and-send`,
/// API-20 `POST /mail-drafts/{draft_id}/reconcile`,
/// `POST /mail-drafts/{draft_id}/withdraw` (unsent draft, X-2).
abstract interface class MailDraftDataSource {
  Future<Map<String, dynamic>> fetchDrafts(String caseId, {String? cursor});

  Future<Map<String, dynamic>> fetchDraft(String draftId);

  Future<Map<String, dynamic>> createRevision(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, dynamic>> approveAndSend(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, dynamic>> reconcile(
    String draftId, {
    required String idempotencyKey,
  });

  Future<Map<String, dynamic>> withdraw(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class MailDraftApiException implements Exception {
  const MailDraftApiException(
    this.statusCode,
    this.code,
    this.message, {
    this.unknownOutcome = false,
  });

  final int statusCode;
  final String code;
  final String message;

  /// 응답을 받지 못함. 서버가 접수했는지 알 수 없습니다.
  final bool unknownOutcome;
}

class ApiMailDraftDataSource implements MailDraftDataSource {
  const ApiMailDraftDataSource(this._dio, this._accessToken);

  static const _drafts = "/api/v1/mail-drafts";

  final Dio _dio;
  final Future<String?> Function({bool forceRefresh}) _accessToken;

  @override
  Future<Map<String, dynamic>> fetchDrafts(String caseId, {String? cursor}) =>
      _send(
        (headers) => _dio.get<Map<String, dynamic>>(
          "/api/v1/work-cases/$caseId/mail-drafts",
          queryParameters: {"limit": 100, "cursor": ?cursor},
          options: Options(headers: headers),
        ),
      );

  @override
  Future<Map<String, dynamic>> fetchDraft(String draftId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_drafts/$draftId",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> createRevision(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_drafts/$draftId/revisions",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> approveAndSend(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_drafts/$draftId/approve-and-send",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> reconcile(
    String draftId, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_drafts/$draftId/reconcile",
      data: const <String, Object?>{},
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> withdraw(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_drafts/$draftId/withdraw",
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
        throw const MailDraftApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
      }
      try {
        final response = await request({
          "Authorization": "Bearer $token",
          "Idempotency-Key": ?idempotencyKey,
        });
        final body = response.data;
        if (body == null) {
          throw const MailDraftApiException(
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
    throw const MailDraftApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
  }

  static MailDraftApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const MailDraftApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
        unknownOutcome: true,
      );
    }
    final data = response.data;
    final detail = data is Map<String, dynamic> ? data["error"] : null;
    final status = response.statusCode ?? 0;
    return MailDraftApiException(
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
