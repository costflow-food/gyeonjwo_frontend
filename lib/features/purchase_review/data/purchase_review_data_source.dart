import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
import "../../auth/data/auth_session_data_source.dart";

part "purchase_review_data_source.g.dart";

@Riverpod(keepAlive: true)
PurchaseReviewDataSource purchaseReviewDataSource(Ref ref) =>
    ApiPurchaseReviewDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-13 `GET /work-cases/{case_id}/quotes`,
/// API-14 `GET /work-cases/{case_id}/review-card`,
/// API-15 `POST /work-cases/{case_id}/decisions`.
abstract interface class PurchaseReviewDataSource {
  Future<Map<String, dynamic>> fetchReviewCard(String caseId);

  Future<Map<String, dynamic>> fetchQuotes(String caseId);

  Future<Map<String, dynamic>> submitDecision(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class ApiPurchaseReviewDataSource implements PurchaseReviewDataSource {
  const ApiPurchaseReviewDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";

  final Dio _dio;
  final ApiTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchReviewCard(String caseId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_cases/$caseId/review-card",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> fetchQuotes(String caseId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_cases/$caseId/quotes",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> submitDecision(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/decisions",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  /// 세션 갱신·429 대기·오류 변환은 [sendApiRequest]가 맡습니다.
  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) async {
    try {
      return await sendApiRequest(
        _accessToken,
        request,
        idempotencyKey: idempotencyKey,
      );
    } on ApiException catch (error) {
      // The route itself is missing until the server ships API-13/14/15.
      if (error.statusCode == 404 && error.code == "HTTP_404") {
        throw ApiException(404, "REVIEW_NOT_READY", error.message);
      }
      rethrow;
    }
  }
}
