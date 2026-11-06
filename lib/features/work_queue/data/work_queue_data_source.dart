import "dart:convert";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/preview_workspace.dart";
import "../../auth/data/auth_session_data_source.dart";
import "work_queue_preview_data.dart";

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
  /// [archived]: the archive (보관함) instead of the open queue.
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
    int? limit,
    bool archived = false,
  });

  Future<Map<String, dynamic>> fetchOriginalMail(String mailId);

  /// API-08 `POST /work-cases/{case_id}/archive`.
  Future<Map<String, dynamic>> archive(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  /// API-09 `POST /work-cases/{case_id}/restore`.
  Future<Map<String, dynamic>> restore(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

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
    bool archived = false,
  }) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      _cases,
      queryParameters: {
        "status": ?status,
        if (query.isNotEmpty) "q": query,
        "cursor": ?cursor,
        "limit": ?limit,
        if (archived) "archived": true,
      },
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> archive(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/archive",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> restore(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/restore",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
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

/// 합성 업무만 메모리에 둡니다. 서버 규칙을 흉내 내지 않고 화면 확인용 응답만 돌려줍니다.
class PreviewWorkQueueDataSource implements WorkQueueDataSource {
  PreviewWorkQueueDataSource({
    this.latency = const Duration(milliseconds: 250),
    this.stepDelay = const Duration(seconds: 3),
    PreviewWorkspace? workspace,
  }) : _workspace = workspace ?? PreviewWorkspace();

  final Duration latency;

  /// Time each preview pipeline step takes after START/RESUME.
  final Duration stepDelay;
  final PreviewWorkspace _workspace;

  @override
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
    int? limit,
    bool archived = false,
  }) async {
    await Future<void>.delayed(latency);
    _workspace.queueCases.forEach(_advance);
    final keyword = query.trim().toLowerCase();
    final searched = [
      for (final item in _workspace.queueCases)
        if ((item["archived_at"] != null) == archived &&
            (keyword.isEmpty ||
                "${item["title"]} ${item["sender"]}".toLowerCase().contains(
                  keyword,
                )))
          item,
    ];
    int count(String value) =>
        searched.where((item) => item["status"] == value).length;
    return _copy({
      "data": {
        "items": [
          for (final item in searched)
            if (status == null || item["status"] == status)
              _withCaseChanges(item),
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
  Future<Uint8List> fetchAttachmentContent(
    String mailId,
    String attachmentId,
  ) async {
    await Future<void>.delayed(latency);
    final attachments =
        _workspace.mails[mailId]?["attachments"] as List? ?? const [];
    final attachment = attachments
        .cast<Map<String, dynamic>>()
        .where((entry) => entry["attachment_id"] == attachmentId)
        .firstOrNull;
    if (attachment == null) {
      throw const WorkQueueApiException(
        404,
        "RESOURCE_NOT_FOUND",
        "첨부파일을 찾을 수 없어요.",
      );
    }
    // 어떤 PDF 첨부든 같은 합성 문서를 돌려줍니다.
    return base64Decode(workQueuePreviewPdfBase64);
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

  /// ARCHIVE/RESTORE the way the server allows them (case_actions.py):
  /// archive from Waiting, Pending, or Complete; restore once archived.
  static Map<String, dynamic> _withCaseChanges(Map<String, dynamic> item) {
    final archived = item["archived_at"] != null;
    final canArchive =
        !archived &&
        const {"Waiting", "Pending", "Complete"}.contains(item["status"]);
    return {
      ...item,
      "allowed_actions": [
        ...(item["allowed_actions"] as List).cast<String>(),
        if (archived) "RESTORE",
        if (canArchive) "ARCHIVE",
      ],
    };
  }

  /// Archive/restore only flip archived_at; the server keeps the step.
  @override
  Future<Map<String, dynamic>> archive(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _setArchived(caseId, archived: true);

  @override
  Future<Map<String, dynamic>> restore(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _setArchived(caseId, archived: false);

  Future<Map<String, dynamic>> _setArchived(
    String caseId, {
    required bool archived,
  }) async {
    await Future<void>.delayed(latency);
    final item = _case(caseId);
    if ((item["archived_at"] != null) == archived) {
      throw const WorkQueueApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "현재 상태에서는 업무를 보관하거나 복원할 수 없습니다.",
      );
    }
    item["archived_at"] = archived
        ? DateTime.now().toUtc().toIso8601String()
        : null;
    return _copy({
      "data": {"case_id": caseId, "input_revision": item["input_revision"]},
      "meta": {"request_id": "req-preview-archive"},
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
    _startedAt[caseId] = DateTime.now();
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

  /// When START/RESUME was accepted; steps move on from here over time.
  final Map<String, DateTime> _startedAt = {};

  /// Stands in for the server pipeline: extraction, then candidates.
  void _advance(Map<String, dynamic> item) {
    final since = _startedAt[item["case_id"]];
    if (since == null) return;
    final elapsed = DateTime.now().difference(since);
    void step(String code, String message) => item
      ..["processing_step"] = code
      ..["step_detail"] = {"code": code, "message": message};
    if (elapsed >= stepDelay * 2) {
      _startedAt.remove(item["case_id"]);
      final set = _workspace.candidateSets[item["case_id"]];
      if (set != null) {
        step("CANDIDATES", "견적 요청 준비 중");
        item["allowed_actions"] = ["VIEW_ORIGINAL", "SELECT_CANDIDATES"];
      } else {
        step("NEEDS_INFO", "추가 정보 확인 필요");
        item["hold"] = {
          "code": "NO_SUITABLE_CANDIDATES",
          "message": "요청 조건에 맞는 거래처 후보를 찾지 못했어요.",
        };
      }
    } else if (elapsed >= stepDelay) {
      step("SELECTING_CANDIDATES", "후보 찾기 대기");
    }
  }

  @override
  Future<Map<String, dynamic>> fetchCase(String caseId) async {
    await Future<void>.delayed(latency);
    final item = _case(caseId);
    _advance(item);
    return _copy({
      "data": {
        "case_id": caseId,
        "initial_mail_id": item["initial_mail_id"],
        "status": item["status"],
        "processing_step": item["processing_step"],
        "input_revision": item["input_revision"],
        "item_name": item["item_name"],
        "specification": null,
        "quantity": null,
        "unit": null,
        "decision": null,
        "archived_at": item["archived_at"],
        "batch_id": "b-preview-$caseId",
        "progress_url": "/api/v1/work-cases/$caseId/progress",
        "allowed_actions": _withCaseChanges(item)["allowed_actions"],
        "disabled_actions": item["disabled_actions"] ?? const [],
      },
      "meta": {"request_id": "req-preview-case"},
    });
  }

  /// API-03 shape for [PreviewReviewProgressDataSource], so a START here
  /// advances the steps shown in the review progress dialog.
  Future<Map<String, dynamic>> fetchProgress(String caseId) async {
    await Future<void>.delayed(latency);
    final item = _case(caseId);
    _advance(item);
    return _copy({
      "data": {
        "case_id": caseId,
        "status": item["status"],
        "processing_step": item["processing_step"],
        "hold": item["hold"],
        "input_revision": item["input_revision"],
        "updated_at": null,
        "batch_id": "b-preview-$caseId",
        "progress_url": "/api/v1/work-cases/$caseId/progress",
        "error": item["error"],
      },
      "meta": {"request_id": "req-preview-progress"},
    });
  }

  @override
  Future<Map<String, dynamic>> resume(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final item = _waitingCase(caseId, "RESUME");
    _startedAt[caseId] = DateTime.now();
    item
      ..["status"] = "Running"
      ..["processing_step"] = "EXTRACTING"
      ..["step_detail"] = {"code": "EXTRACTING", "message": "요청 정보 확인 중"}
      ..["hold"] = null
      ..["allowed_actions"] = ["VIEW_ORIGINAL"]
      ..["disabled_actions"] = [];
    return _copy({
      "data": {
        "case_id": caseId,
        "input_revision": item["input_revision"],
        "batch_id": "b-preview-$caseId",
        "progress_url": "/api/v1/work-cases/$caseId/progress",
      },
      "meta": {"request_id": "req-preview-resume"},
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
    final set = _workspace.candidateSets[caseId]!;
    final selected = (body["selected_supplier_ids"] as List).cast<String>();
    if (set["candidate_set_id"] != body["candidate_set_id"]) {
      throw const WorkQueueApiException(
        409,
        "CANDIDATES_CHANGED",
        "후보 세트가 바뀌었습니다. 다시 확인해 주세요.",
      );
    }
    set
      ..["selected_supplier_ids"] = selected
      // Like the server: a set is chosen once; the drafts carry on from here.
      ..["allowed_actions"] = <String>[]
      ..["disabled_actions"] = [
        {
          "action": "SELECT_CANDIDATES",
          "reason_code": "ACTION_NOT_ALLOWED",
          "message": "이미 요청 대상을 선택했습니다. 현재 초안·발송 상태를 확인해 주세요.",
        },
      ];
    // One RFQ draft per supplier, with the effective send policy applied.
    final drafts = _workspace.drafts.putIfAbsent(caseId, () => []);
    final results = <Map<String, Object?>>[];
    for (final supplierId in selected) {
      final candidate = (set["items"] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry["supplier_id"] == supplierId);
      final draft = <String, dynamic>{
        "draft_id": "draft-$caseId-$supplierId",
        "case_id": caseId,
        "supplier_id": supplierId,
        "supplier_name": candidate["name"],
        "purpose": "RFQ",
        "recipient": candidate["contact_email"] ?? "unknown@example.invalid",
        "subject": "[견적 요청] ${item["item_name"] ?? "품목"}",
        "body_text":
            "안녕하세요, 구매팀입니다.\n\n${item["item_name"] ?? "요청 품목"} 공급 견적을 요청드립니다. "
            "단가, 공급 가능 수량, 납기를 알려주시면 감사하겠습니다.\n\n구매팀 드림",
        "status": "DRAFT",
        "input_revision": item["input_revision"],
        "replaces_id": null,
        "sent_at": null,
        "provider_message_id": null,
      };
      _workspace.applyDraftPolicy(draft);
      final String state;
      if (draft["settings_configured"] != true) {
        state = "BLOCKED_POLICY";
      } else if (draft["approval_required"] == true) {
        state = "WAITING_APPROVAL";
      } else if (draft["auto_send_allowed"] == true) {
        state = "AUTO_QUEUED";
        draft["status"] = "SENDING";
        _workspace.sendingSince[draft["draft_id"] as String] = DateTime.now();
      } else {
        state = "BLOCKED_POLICY";
      }
      drafts
        ..removeWhere((entry) => entry["draft_id"] == draft["draft_id"])
        ..add(draft);
      results.add({
        "draft_id": draft["draft_id"],
        "supplier_id": supplierId,
        "dispatch_state": state,
      });
    }
    item
      ..["processing_step"] = "AWAITING_APPROVAL"
      ..["step_detail"] = {"code": "AWAITING_APPROVAL", "message": "발송 승인 대기"}
      ..["allowed_actions"] = ["VIEW_ORIGINAL"];
    return _copy({
      "data": {
        "case_id": caseId,
        "candidate_set_id": set["candidate_set_id"],
        "revision": set["revision"],
        "selection_revision": 1,
        "selected_supplier_ids": selected,
        "drafts": results,
        "selection_policy": "PRESERVE_MAILBOX_LIMIT",
      },
      "meta": {"request_id": "req-preview-candidate-selection"},
    });
  }

  Map<String, dynamic> _case(String caseId) {
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
    return item;
  }

  Map<String, dynamic> _waitingCase(String caseId, String action) {
    final item = _case(caseId);
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
