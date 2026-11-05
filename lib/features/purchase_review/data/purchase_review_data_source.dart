import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";
import "../../work_queue/data/work_queue_data_source.dart";
import "purchase_review_preview_data.dart";

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

/// 합성 카드만 메모리에 둡니다. 서버 규칙을 흉내 내지 않고 화면 확인용 응답만 돌려줍니다.
class PreviewPurchaseReviewDataSource implements PurchaseReviewDataSource {
  PreviewPurchaseReviewDataSource({
    this.latency = const Duration(milliseconds: 250),
  }) : _cards = previewReviewCards();

  final Duration latency;
  final Map<String, Map<String, dynamic>> _cards;

  Map<String, dynamic> _card(String caseId) {
    final card = _cards[caseId];
    if (card == null) {
      throw const PurchaseReviewApiException(
        404,
        "REVIEW_NOT_READY",
        "아직 검토 카드가 없어요.",
      );
    }
    return card;
  }

  @override
  Future<Map<String, dynamic>> fetchReviewCard(String caseId) async {
    await Future<void>.delayed(latency);
    return copyJson({
      "data": _card(caseId),
      "meta": {"request_id": "req-preview-review-card"},
    });
  }

  @override
  Future<Map<String, dynamic>> fetchQuotes(String caseId) async {
    await Future<void>.delayed(latency);
    _card(caseId);
    return copyJson({
      "data": {
        "items": previewReviewQuotes[caseId] ?? const [],
        "next_cursor": null,
      },
      "meta": {"request_id": "req-preview-quotes"},
    });
  }

  @override
  Future<Map<String, dynamic>> submitDecision(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final card = _card(caseId);
    if (body["expected_revision"] != card["input_revision"] ||
        body["review_revision"] != card["review_revision"]) {
      throw const PurchaseReviewApiException(
        409,
        "REVISION_CONFLICT",
        "새 견적이 반영되었습니다. 최신 내용을 확인해 주세요.",
      );
    }
    final decision = body["decision"] as String;
    final allowed = (card["allowed_actions"] as List).cast<String>();
    if (!allowed.contains(decision)) {
      throw const PurchaseReviewApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "지금은 이 판단을 저장할 수 없어요.",
      );
    }
    if (decision == "SELECT_PLAN") {
      final plan = (card["plans"] as List)
          .cast<Map<String, dynamic>>()
          .where((plan) => plan["plan_id"] == body["plan_id"])
          .firstOrNull;
      if (plan == null || plan["validation_status"] != "VALID") {
        throw const PurchaseReviewApiException(
          422,
          "INVALID_PLAN_SELECTION",
          "최신 카드의 확정 가능한 안만 선택할 수 있어요.",
        );
      }
    }
    card["decision"] = {
      "decision": decision,
      "plan_id": body["plan_id"],
      "note": body["note"],
      "decided_at": DateTime.now().toUtc().toIso8601String(),
    };
    card["allowed_actions"] = switch (decision) {
      "SELECT_PLAN" => ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
      "HOLD" => ["SELECT_PLAN", "CONFIRM_REVIEW"],
      _ => <String>[],
    };
    return copyJson({
      "data": {
        "case_id": caseId,
        "decision": decision,
        "review_revision": card["review_revision"],
        "input_revision": card["input_revision"],
      },
      "meta": {"request_id": "req-preview-decision"},
    });
  }
}
