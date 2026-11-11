import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
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

class ApiMailDraftDataSource implements MailDraftDataSource {
  const ApiMailDraftDataSource(this._dio, this._accessToken);

  static const _drafts = "/api/v1/mail-drafts";

  final Dio _dio;
  final ApiTokenReader _accessToken;

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

  /// 세션 갱신·429 대기·오류 변환은 [sendApiRequest]가 맡습니다.
  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) => sendApiRequest(_accessToken, request, idempotencyKey: idempotencyKey);
}
