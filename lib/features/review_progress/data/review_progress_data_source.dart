import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../auth/data/auth_session_data_source.dart";
import "../../work_queue/data/work_queue_data_source.dart";

part "review_progress_data_source.g.dart";

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
@Riverpod(keepAlive: true)
ReviewProgressDataSource reviewProgressDataSource(Ref ref) =>
    ApiReviewProgressDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-03 `GET /work-cases/{case_id}/progress`. 조회만 하며 업무를 바꾸지 않습니다.
abstract interface class ReviewProgressDataSource {
  Future<Map<String, dynamic>> fetchProgress(String caseId);
}

class ReviewProgressApiException implements Exception {
  const ReviewProgressApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;
}

class ApiReviewProgressDataSource implements ReviewProgressDataSource {
  const ApiReviewProgressDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";

  final Dio _dio;
  final AccessTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchProgress(String caseId) async {
    // 만료된 세션은 한 번 갱신해 다시 보냅니다.
    for (final forceRefresh in const [false, true]) {
      final token = await _accessToken(forceRefresh: forceRefresh);
      if (token == null) {
        throw const ReviewProgressApiException(
          401,
          "AUTH_REQUIRED",
          "다시 로그인해 주세요.",
        );
      }
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          "$_cases/$caseId/progress",
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
        final body = response.data;
        if (body == null) {
          throw const ReviewProgressApiException(
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
    throw const ReviewProgressApiException(
      401,
      "AUTH_REQUIRED",
      "다시 로그인해 주세요.",
    );
  }

  static ReviewProgressApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ReviewProgressApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
      );
    }
    final body = response.data;
    final detail = body is Map<String, dynamic> ? body["error"] : null;
    final status = response.statusCode ?? 0;
    return ReviewProgressApiException(
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

/// 미리보기 업무 큐의 진행 단계를 그대로 돌려줍니다.
/// 미리보기에서 검토를 시작하면 이 팝업의 단계도 같이 바뀝니다.
class PreviewReviewProgressDataSource implements ReviewProgressDataSource {
  PreviewReviewProgressDataSource(
    this._queue, {
    this.demoCaseId,
    this.stepDelay = const Duration(seconds: 3),
  });

  final PreviewWorkQueueDataSource _queue;

  /// 미리보기 목록의 '검토 진행' 시연용 업무. 처음 조회한 때부터
  /// 추출 → 후보 → 회신 검토 → 카드 준비 완료까지 [stepDelay]마다 넘어갑니다.
  final String? demoCaseId;
  final Duration stepDelay;

  static const _demoSteps = [
    "EXTRACTING",
    "SELECTING_CANDIDATES",
    "GENERATING_PLANS",
    "REVIEW_READY",
  ];
  DateTime? _demoStartedAt;

  @override
  Future<Map<String, dynamic>> fetchProgress(String caseId) async {
    if (caseId == demoCaseId) return _demo(caseId);
    try {
      return await _queue.fetchProgress(caseId);
    } on WorkQueueApiException catch (error) {
      throw ReviewProgressApiException(
        error.statusCode,
        error.code,
        error.message,
      );
    }
  }

  Map<String, dynamic> _demo(String caseId) {
    final startedAt = _demoStartedAt ??= DateTime.now();
    final elapsed = DateTime.now().difference(startedAt);
    final index = stepDelay == Duration.zero
        ? _demoSteps.length - 1
        : (elapsed.inMilliseconds ~/ stepDelay.inMilliseconds).clamp(
            0,
            _demoSteps.length - 1,
          );
    final step = _demoSteps[index];
    return {
      "data": {
        "case_id": caseId,
        "status": step == "REVIEW_READY" ? "Complete" : "Running",
        "processing_step": step,
        "hold": null,
        "input_revision": 1,
        "updated_at": null,
        "batch_id": "b-preview-$caseId",
        "progress_url": "/api/v1/work-cases/$caseId/progress",
        "error": null,
      },
      "meta": {"request_id": "req-preview-progress"},
    };
  }
}
