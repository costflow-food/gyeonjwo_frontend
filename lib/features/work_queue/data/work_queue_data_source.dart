import "dart:convert";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/preview_workspace.dart";
import "../../auth/data/auth_session_data_source.dart";

part "work_queue_data_source.g.dart";

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
@Riverpod(keepAlive: true)
WorkQueueDataSource workQueueDataSource(Ref ref) => ApiWorkQueueDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// API-01 `GET /work-cases`, API-25 `GET /mail-messages/{mail_id}`,
/// API-04 `POST /work-cases/{case_id}/start`,
/// API-05 `POST /work-cases/{case_id}/accept-increase`,
/// API-11 `GET /work-cases/{case_id}/candidates`,
/// API-12 `PUT /work-cases/{case_id}/candidate-selection`.
abstract interface class WorkQueueDataSource {
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
  });

  Future<Map<String, dynamic>> fetchOriginalMail(String mailId);

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
  }) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      _cases,
      queryParameters: {
        "status": ?status,
        if (query.isNotEmpty) "q": query,
        "cursor": ?cursor,
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
  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function(Map<String, String> headers)
    request, {
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
    final body = response.data;
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
}

/// 합성 업무만 메모리에 둡니다. 서버 규칙을 흉내 내지 않고 화면 확인용 응답만 돌려줍니다.
class PreviewWorkQueueDataSource implements WorkQueueDataSource {
  PreviewWorkQueueDataSource({
    this.latency = const Duration(milliseconds: 250),
    PreviewWorkspace? workspace,
  }) : _workspace = workspace ?? PreviewWorkspace();

  final Duration latency;
  final PreviewWorkspace _workspace;

  @override
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
  }) async {
    await Future<void>.delayed(latency);
    final keyword = query.trim().toLowerCase();
    final searched = [
      for (final item in _workspace.queueCases)
        if (keyword.isEmpty ||
            "${item["title"]} ${item["sender"]}".toLowerCase().contains(
              keyword,
            ))
          item,
    ];
    int count(String value) =>
        searched.where((item) => item["status"] == value).length;
    return _copy({
      "data": {
        "items": [
          for (final item in searched)
            if (status == null || item["status"] == status) item,
        ],
        "next_cursor": null,
        "counts": {
          "Waiting": count("Waiting"),
          "Running": count("Running"),
          "Complete": count("Complete"),
          "total": searched.length,
        },
        "intake_pending": 0,
      },
      "meta": {"request_id": "req-preview-work-cases"},
    });
  }

  @override
  Future<Map<String, dynamic>> fetchOriginalMail(String mailId) async {
    await Future<void>.delayed(latency);
    final mail = _workspace.mails[mailId];
    if (mail == null) {
      throw const WorkQueueApiException(
        404,
        "RESOURCE_NOT_FOUND",
        "메일 원문을 찾을 수 없어요.",
      );
    }
    return _copy({
      "data": mail,
      "meta": {"request_id": "req-preview-mail"},
    });
  }

  @override
  Future<Map<String, dynamic>> acceptIncrease(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    _waitingCase(caseId, "ACCEPT_INCREASE");
    _workspace.queueCases.removeWhere((item) => item["case_id"] == caseId);
    return _copy({
      "data": {"case_id": caseId, "deleted": true},
      "meta": {"request_id": "req-preview-accept"},
    });
  }

  @override
  Future<Map<String, dynamic>> start(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final item = _waitingCase(caseId, "START");
    item
      ..["status"] = "Running"
      ..["processing_step"] = "EXTRACTING"
      ..["step_detail"] = {"code": "EXTRACTING", "message": "요청 정보 추출 중"}
      ..["allowed_actions"] = ["VIEW_ORIGINAL"];
    return _copy({
      "data": {
        "case_id": caseId,
        "input_revision": item["input_revision"],
        "batch_id": "b-preview-$caseId",
        "progress_url": "/api/v1/work-cases/$caseId/progress",
      },
      "meta": {"request_id": "req-preview-start"},
    });
  }

  @override
  Future<Map<String, dynamic>> fetchCandidates(String caseId) async {
    await Future<void>.delayed(latency);
    final set = _workspace.candidateSets[caseId];
    if (set == null) {
      throw const WorkQueueApiException(
        404,
        "CANDIDATES_NOT_READY",
        "아직 후보를 고르지 않은 업무예요.",
      );
    }
    return _copy({
      "data": set,
      "meta": {"request_id": "req-preview-candidates"},
    });
  }

  @override
  Future<Map<String, dynamic>> selectCandidates(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final item = _workspace.queueCases
        .where((item) => item["case_id"] == caseId)
        .firstOrNull;
    if (item == null ||
        !(item["allowed_actions"] as List).contains("SELECT_CANDIDATES")) {
      throw const WorkQueueApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "현재 상태에서는 견적 요청 대상을 고를 수 없어요.",
      );
    }
    _workspace.candidateSets[caseId]!["selected_supplier_ids"] =
        body["selected_supplier_ids"];
    // Approval ON (the preview default): drafts wait for approval.
    item
      ..["processing_step"] = "AWAITING_APPROVAL"
      ..["step_detail"] = {"code": "AWAITING_APPROVAL", "message": "발송 승인 대기"}
      ..["allowed_actions"] = ["VIEW_ORIGINAL"];
    return _copy({
      "data": {"case_id": caseId, "selected_supplier_ids": body["selected_supplier_ids"]},
      "meta": {"request_id": "req-preview-candidate-selection"},
    });
  }

  Map<String, dynamic> _waitingCase(String caseId, String action) {
    final item = _workspace.queueCases
        .where((item) => item["case_id"] == caseId)
        .firstOrNull;
    if (item == null) {
      throw const WorkQueueApiException(
        404,
        "RESOURCE_NOT_FOUND",
        "업무를 찾을 수 없어요.",
      );
    }
    if (!(item["allowed_actions"] as List).contains(action)) {
      throw const WorkQueueApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "현재 상태에서는 처리할 수 없어요.",
      );
    }
    return item;
  }

  static Map<String, dynamic> _copy(Map<String, Object?> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
