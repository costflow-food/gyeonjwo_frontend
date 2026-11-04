import "dart:convert";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/preview_workspace.dart";
import "../../auth/data/auth_session_data_source.dart";

part "mail_draft_data_source.g.dart";

/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
@Riverpod(keepAlive: true)
MailDraftDataSource mailDraftDataSource(Ref ref) => ApiMailDraftDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// API-16 `GET /work-cases/{case_id}/mail-drafts`,
/// API-17 `GET /mail-drafts/{draft_id}`,
/// API-18 `POST /mail-drafts/{draft_id}/revisions` (not on the server yet),
/// API-19 `POST /mail-drafts/{draft_id}/approve-and-send`,
/// API-20 `POST /mail-drafts/{draft_id}/reconcile`.
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

/// In-memory drafts answered in the real API-16·17·19·20 shape. A send moves
/// to SENT on a read after [sendDelay], standing in for the server's Gmail
/// result.
class PreviewMailDraftDataSource implements MailDraftDataSource {
  PreviewMailDraftDataSource({
    this.latency = const Duration(milliseconds: 250),
    this.sendDelay = const Duration(seconds: 2),
    PreviewWorkspace? workspace,
  }) : _workspace = workspace ?? PreviewWorkspace();

  final Duration latency;
  final Duration sendDelay;
  final PreviewWorkspace _workspace;
  Map<String, List<Map<String, dynamic>>> get _drafts => _workspace.drafts;
  Map<String, DateTime> get _sendingSince => _workspace.sendingSince;
  final Map<String, (String, Map<String, dynamic>)> _results = {};

  @override
  Future<Map<String, dynamic>> fetchDrafts(
    String caseId, {
    String? cursor,
  }) async {
    await Future<void>.delayed(latency);
    final drafts = _drafts[caseId] ?? const [];
    for (final draft in drafts) {
      _settleSending(draft);
    }
    return {
      "data": {
        "items": [for (final draft in drafts) _present(draft)],
        "next_cursor": null,
      },
      "meta": {"request_id": "req-preview-mail-drafts"},
    };
  }

  @override
  Future<Map<String, dynamic>> fetchDraft(String draftId) async {
    await Future<void>.delayed(latency);
    final (_, draft) = _find(draftId);
    _settleSending(draft);
    return {
      "data": _present(draft),
      "meta": {"request_id": "req-preview-mail-draft"},
    };
  }

  @override
  Future<Map<String, dynamic>> createRevision(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    throw const MailDraftApiException(
      404,
      "RESOURCE_NOT_FOUND",
      "초안 수정본 저장 기능이 아직 없어요.",
    );
  }

  @override
  Future<Map<String, dynamic>> approveAndSend(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _once(idempotencyKey, {"approve": draftId, ...body}, () {
    final (_, draft) = _find(draftId);
    final view = _present(draft);
    final policy = view["effective_send_policy"] as Map<String, dynamic>;
    if (draft["status"] != "DRAFT" ||
        policy["configured"] != true ||
        policy["approval_required"] != true) {
      throw const MailDraftApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "최신 초안·설정과 서버 실행 상태를 확인해 주세요.",
      );
    }
    if (view["snapshot_hash"] != body["snapshot_hash"] ||
        policy["settings_version"] != body["expected_settings_version"]) {
      throw const MailDraftApiException(
        409,
        "DRAFT_CHANGED",
        "최신 초안·설정과 서버 실행 상태를 확인해 주세요.",
      );
    }
    draft["status"] = "SENDING";
    _sendingSince[draftId] = DateTime.now();
    return draftId;
  });

  @override
  Future<Map<String, dynamic>> reconcile(
    String draftId, {
    required String idempotencyKey,
  }) => _once(idempotencyKey, {"reconcile": draftId}, () {
    final (_, draft) = _find(draftId);
    if (draft["status"] != "UNKNOWN") {
      throw const MailDraftApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "최신 초안·설정과 서버 실행 상태를 확인해 주세요.",
      );
    }
    // The preview finds the message in the sent folder.
    draft["status"] = "SENT";
    draft["sent_at"] = DateTime.now().toUtc().toIso8601String();
    draft["provider_message_id"] = "gmail-msg-preview-reconciled";
    return draftId;
  });

  /// 202 acceptance, replayed for the same key and body.
  Future<Map<String, dynamic>> _once(
    String key,
    Map<String, Object?> body,
    String Function() run,
  ) async {
    await Future<void>.delayed(latency);
    final hash = jsonEncode(body);
    final previous = _results[key];
    if (previous != null) {
      if (previous.$1 != hash) {
        throw const MailDraftApiException(
          409,
          "IDEMPOTENCY_KEY_REUSED",
          "이미 다른 내용으로 접수된 요청입니다.",
        );
      }
      return previous.$2;
    }
    final draftId = run();
    final response = {
      "data": {
        "draft_id": draftId,
        "accepted": true,
        "draft_url": "/api/v1/mail-drafts/$draftId",
      },
      "meta": {"request_id": "req-preview-mail-draft-action"},
    };
    _results[key] = (hash, response);
    return response;
  }

  (String, Map<String, dynamic>) _find(String draftId) {
    for (final entry in _drafts.entries) {
      for (final draft in entry.value) {
        if (draft["draft_id"] == draftId) return (entry.key, draft);
      }
    }
    throw const MailDraftApiException(
      404,
      "RESOURCE_NOT_FOUND",
      "메일 초안을 찾을 수 없습니다.",
    );
  }

  void _settleSending(Map<String, dynamic> draft) {
    final since = _sendingSince[draft["draft_id"]];
    if (draft["status"] != "SENDING" || since == null) return;
    if (DateTime.now().difference(since) < sendDelay) return;
    draft["status"] = "SENT";
    draft["sent_at"] = DateTime.now().toUtc().toIso8601String();
    draft["provider_message_id"] = "gmail-msg-preview-${draft["draft_id"]}";
    _sendingSince.remove(draft["draft_id"]);
  }

  /// The server's draft DTO: no supplier name, evidence, or action lists.
  static Map<String, dynamic> _present(Map<String, dynamic> draft) {
    final configured = draft["settings_configured"] as bool? ?? true;
    final version = draft["settings_version"];
    final view = <String, dynamic>{
      "draft_id": draft["draft_id"],
      "case_id": draft["case_id"],
      "supplier_id": draft["supplier_id"],
      "purpose": draft["purpose"],
      "recipient": draft["recipient"],
      "subject": draft["subject"],
      "body_text": draft["body_text"],
      "input_revision": draft["input_revision"],
      "status": draft["status"],
      "replaces_id": draft["replaces_id"],
      "is_stale": false,
      "effective_send_policy": {
        "configured": configured,
        "approval_required": configured ? draft["approval_required"] : null,
        // Opaque string like the server's; never a local counter.
        "settings_version": configured && version != null
            ? "preview-settings-v$version"
            : null,
      },
      "provider_message_id": draft["status"] == "SENT"
          ? draft["provider_message_id"]
          : null,
      "sent_at": draft["sent_at"],
    };
    view["snapshot_hash"] = _hash(view);
    return jsonDecode(jsonEncode(view)) as Map<String, dynamic>;
  }

  static String _hash(Map<String, dynamic> view) =>
      "preview-${jsonEncode([view["draft_id"], view["recipient"], view["subject"], view["body_text"], view["input_revision"]]).hashCode}";
}
