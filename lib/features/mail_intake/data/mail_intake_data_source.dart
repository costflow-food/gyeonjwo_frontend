import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/preview_workspace.dart";

import "mail_intake_preview_data.dart";

part "mail_intake_data_source.g.dart";

@Riverpod(keepAlive: true)
MailIntakeDataSource mailIntakeDataSource(Ref ref) {
  return PreviewMailIntakeDataSource(
    workspace: ref.watch(previewWorkspaceProvider),
  );
}

/// API-23 `GET /mail-intake`, API-24 `POST /mail-messages/{mail_id}/resolve`.
abstract interface class MailIntakeDataSource {
  Future<Map<String, dynamic>> fetchPending({String? cursor, int limit = 25});

  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class MailIntakeApiException implements Exception {
  const MailIntakeApiException(this.statusCode, this.code, this.message);
  final int statusCode;
  final String code;
  final String message;
}

/// Resolved mails disappear from the list for the rest of the app session.
class PreviewMailIntakeDataSource implements MailIntakeDataSource {
  PreviewMailIntakeDataSource({
    this.latency = const Duration(milliseconds: 250),
    PreviewWorkspace? workspace,
  }) : _workspace = workspace ?? PreviewWorkspace(),
       _items = [
         for (final item in mailIntakePreviewItems)
           jsonDecode(jsonEncode(item)) as Map<String, dynamic>,
       ];

  final Duration latency;
  final PreviewWorkspace _workspace;
  final List<Map<String, dynamic>> _items;
  final Map<String, (String, Map<String, dynamic>)> _results = {};

  @override
  Future<Map<String, dynamic>> fetchPending({
    String? cursor,
    int limit = 25,
  }) async {
    await Future<void>.delayed(latency);
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, _items.length);
    return jsonDecode(
      jsonEncode({
        "data": {
          "items": _items.sublist(start, end),
          "next_cursor": end < _items.length ? "$end" : null,
          "total_pending": _items.length,
        },
        "meta": {"request_id": "req-preview-mail-intake"},
      }),
    ) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final hash = jsonEncode(body);
    final previous = _results[idempotencyKey];
    if (previous != null) {
      if (previous.$1 != hash) {
        throw const MailIntakeApiException(
          409,
          "IDEMPOTENCY_KEY_REUSED",
          "이미 다른 내용으로 접수된 요청입니다.",
        );
      }
      return previous.$2;
    }
    final mail = _items.where((item) => item["mail_id"] == mailId).firstOrNull;
    if (mail == null) {
      throw const MailIntakeApiException(
        409,
        "REVISION_CONFLICT",
        "다른 곳에서 이미 처리된 메일입니다. 목록을 새로 불러옵니다.",
      );
    }
    if (mail["revision"] != body["expected_revision"]) {
      throw const MailIntakeApiException(
        409,
        "REVISION_CONFLICT",
        "메일 정보가 바뀌었습니다. 최신 내용을 확인해 주세요.",
      );
    }
    if (body["resolution"] == "LINK_CASE") {
      final candidates = (mail["candidates"] as List)
          .map((candidate) => candidate["case_id"])
          .toSet();
      if (!candidates.contains(body["target_case_id"])) {
        throw const MailIntakeApiException(
          422,
          "INVALID_LINK_TARGET",
          "연결할 수 없는 업무입니다.",
        );
      }
    }
    final caseId = body["resolution"] == "CREATE_CASE"
        ? _workspace.createRequest(mail)
        : body["target_case_id"];
    _items.remove(mail);
    final response = {
      "data": {
        "mail_id": mailId,
        "resolution": body["resolution"],
        "case_id": caseId,
        "case_status": body["resolution"] == "NON_BUSINESS" ? null : "Waiting",
        "total_pending": _items.length,
      },
      "meta": {"request_id": "req-preview-mail-intake-resolve"},
    };
    _results[idempotencyKey] = (hash, response);
    return response;
  }
}
