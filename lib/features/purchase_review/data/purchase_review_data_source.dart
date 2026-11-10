import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";
import "../../work_queue/data/work_queue_data_source.dart";

part "purchase_review_data_source.g.dart";

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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

class PurchaseReviewApiException implements Exception {
  const PurchaseReviewApiException(
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

class ApiPurchaseReviewDataSource implements PurchaseReviewDataSource {
  const ApiPurchaseReviewDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";

  final Dio _dio;
  final AccessTokenReader _accessToken;

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

  /// 만료된 세션은 한 번 갱신해 같은 요청(같은 멱등 키)으로 다시 보냅니다.
  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function(Map<String, String> headers)
    request, {
    String? idempotencyKey,
  }) async {
    for (final forceRefresh in const [false, true]) {
      final token = await _accessToken(forceRefresh: forceRefresh);
      if (token == null) {
        throw const PurchaseReviewApiException(
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
          throw const PurchaseReviewApiException(
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
    throw const PurchaseReviewApiException(
      401,
      "AUTH_REQUIRED",
      "다시 로그인해 주세요.",
    );
  }

  static PurchaseReviewApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const PurchaseReviewApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
        unknownOutcome: true,
      );
    }
    final body = response.data;
    final detail = body is Map<String, dynamic> ? body["error"] : null;
    final status = response.statusCode ?? 0;
    return PurchaseReviewApiException(
      status,
      detail is Map<String, dynamic>
          ? detail["code"] as String? ?? "HTTP_$status"
          : status == 404
          // The route itself is missing until the server ships API-13/14/15.
          ? "REVIEW_NOT_READY"
          : "HTTP_$status",
      detail is Map<String, dynamic>
          ? detail["message"] as String? ?? "요청을 처리하지 못했어요."
          : "요청을 처리하지 못했어요.",
    );
  }
}
