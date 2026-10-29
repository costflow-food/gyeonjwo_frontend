import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/preview_workspace.dart";

part "mail_draft_data_source.g.dart";

@Riverpod(keepAlive: true)
MailDraftDataSource mailDraftDataSource(Ref ref) {
  return PreviewMailDraftDataSource(
    workspace: ref.watch(previewWorkspaceProvider),
  );
}

/// API-16 `GET /work-cases/{case_id}/mail-drafts`,
/// API-18 `POST /mail-drafts/{draft_id}/revisions`,
/// API-19 `POST /mail-drafts/{draft_id}/approve-and-send`,
/// API-20 `POST /mail-drafts/{draft_id}/reconcile`.
abstract interface class MailDraftDataSource {
  Future<Map<String, dynamic>> fetchDrafts(String caseId);

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
  const MailDraftApiException(this.statusCode, this.code, this.message);
  final int statusCode;
  final String code;
  final String message;
}

/// In-memory drafts. A send moves to SENT on the next fetch after
/// [sendDelay], standing in for the server's Gmail result.
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
  Future<Map<String, dynamic>> fetchDrafts(String caseId) async {
    await Future<void>.delayed(latency);
    final drafts = _drafts[caseId] ?? const [];
    for (final draft in drafts) {
      _settleSending(draft);
    }
    return {
      "data": {
        "items": [for (final draft in drafts) _withActions(draft)],
      },
      "meta": {"request_id": "req-preview-mail-drafts"},
    };
  }

  @override
  Future<Map<String, dynamic>> createRevision(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _once(idempotencyKey, body, () {
    final (caseId, draft) = _find(draftId);
    if (draft["status"] != "DRAFT" && draft["status"] != "FAILED") {
      throw const MailDraftApiException(
        409,
        "SEND_RESULT_UNKNOWN",
        "현재 상태에서는 수정본을 만들 수 없습니다.",
      );
    }
    if (_hash(draft) != body["expected_snapshot_hash"]) {
      throw const MailDraftApiException(
        409,
        "DRAFT_CHANGED",
        "초안이 바뀌었습니다. 최신 내용을 확인해 주세요.",
      );
    }
    final sequence = ++_workspace.draftSequence;
    final revision = <String, dynamic>{
      ...draft,
      "draft_id": "${draft["draft_id"]}-r$sequence",
      "recipient": body["recipient"],
      "subject": body["subject"],
      "body_text": body["body_text"],
      // Approval OFF: the server re-validates and dispatches automatically.
      "status": "DRAFT",
      "replaces_id": draft["draft_id"],
      "sent_at": null,
      "provider_message_id": null,
      "failure_message": null,
    };
    _workspace.applyDraftPolicy(revision);
    final automatic =
        revision["approval_required"] == false &&
        revision["settings_configured"] == true &&
        revision["auto_send_allowed"] == true;
    if (automatic) {
      revision['status'] = 'SENDING';
    }
    if (automatic) {
      _sendingSince[revision["draft_id"] as String] = DateTime.now();
    }
    final drafts = _drafts[caseId]!;
    drafts[drafts.indexOf(draft)] = revision;
    return revision;
  });

  @override
  Future<Map<String, dynamic>> approveAndSend(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _once(idempotencyKey, body, () {
    final (_, draft) = _find(draftId);
    if (draft["approval_required"] != true ||
        draft["status"] != "DRAFT" ||
        draft['settings_configured'] == false) {
      throw const MailDraftApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "현재 상태에서는 승인 발송할 수 없습니다.",
      );
    }
    if (_hash(draft) != body["snapshot_hash"]) {
      throw const MailDraftApiException(
        409,
        "DRAFT_CHANGED",
        "초안이 바뀌었습니다. 최신 내용을 확인해 주세요.",
      );
    }
    draft["status"] = "SENDING";
    _sendingSince[draftId] = DateTime.now();
    return draft;
  });

  @override
  Future<Map<String, dynamic>> reconcile(
    String draftId, {
    required String idempotencyKey,
  }) => _once(idempotencyKey, {"draft_id": draftId}, () {
    final (_, draft) = _find(draftId);
    if (draft["status"] != "UNKNOWN") {
      throw const MailDraftApiException(
        409,
        "ACTION_NOT_ALLOWED",
        "발송 여부 확인이 필요한 초안이 아닙니다.",
      );
    }
    // The preview finds the message in the sent folder.
    draft["status"] = "SENT";
    draft["sent_at"] = DateTime.now().toUtc().toIso8601String();
    draft["provider_message_id"] = "gmail-msg-preview-reconciled";
    return draft;
  });

  Future<Map<String, dynamic>> _once(
    String key,
    Map<String, Object?> body,
    Map<String, dynamic> Function() run,
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
    final response = {
      "data": _withActions(run()),
      "meta": {"request_id": "req-preview-mail-draft-change"},
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
      "초안을 찾을 수 없습니다.",
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

  /// The server decides allowed actions from status and policy.
  static Map<String, dynamic> _withActions(Map<String, dynamic> draft) {
    final status = draft["status"] as String;
    final approval = draft["approval_required"] == true;
    final allowed = <String>[];
    final disabled = <Map<String, String>>[];
    void block(String action, String code, String message) => disabled.add({
      "action": action,
      "reason_code": code,
      "message": message,
    });
    switch (status) {
      case "DRAFT":
        allowed.add("EDIT_DRAFT");
        if (draft['settings_configured'] == false) {
          block('APPROVE_SEND', 'SETTINGS_REQUIRED', '발송 설정을 완료해 주세요.');
        } else if (!approval && draft['auto_send_allowed'] == false) {
          block(
            'APPROVE_SEND',
            'OUTSIDE_SEND_SCOPE',
            '자동 발송 허용 업체·수신자 범위 밖입니다. 발송 설정을 확인해 주세요.',
          );
        } else if (approval) {
          allowed.add("APPROVE_SEND");
        } else {
          block("APPROVE_SEND", "APPROVAL_OFF", "승인 OFF 설정이라 검증 후 자동 발송됩니다.");
        }
      case "SENDING":
        block("EDIT_DRAFT", "SENDING", "발송 중에는 수정할 수 없습니다.");
      case "FAILED":
        allowed.add("EDIT_DRAFT");
      case "UNKNOWN":
        allowed.add("RECONCILE_SEND");
        const message = "발송 여부를 확인하기 전에는 수정·재발송할 수 없습니다.";
        block("EDIT_DRAFT", "SEND_RESULT_UNKNOWN", message);
        block("APPROVE_SEND", "SEND_RESULT_UNKNOWN", message);
    }
    final copy = jsonDecode(jsonEncode(draft)) as Map<String, dynamic>;
    return {
      ...copy,
      "snapshot_hash": _hash(copy),
      "allowed_actions": allowed,
      "disabled_actions": disabled,
    };
  }

  static String _hash(Map<String, dynamic> draft) =>
      "preview-${jsonEncode([draft["draft_id"], draft["recipient"], draft["subject"], draft["body_text"], draft['settings_version'], draft['approval_required']]).hashCode}";
}
