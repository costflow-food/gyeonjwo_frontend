import "dart:convert";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/preview_workspace.dart";
import "../../auth/data/auth_session_data_source.dart";

import "mail_intake_preview_data.dart";

part "mail_intake_data_source.g.dart";

/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
@Riverpod(keepAlive: true)
MailIntakeDataSource mailIntakeDataSource(Ref ref) => ApiMailIntakeDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

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
  const MailIntakeApiException(
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

class ApiMailIntakeDataSource implements MailIntakeDataSource {
  const ApiMailIntakeDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final Future<String?> Function({bool forceRefresh}) _accessToken;

  @override
  Future<Map<String, dynamic>> fetchPending({
    String? cursor,
    int limit = 25,
  }) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "/api/v1/mail-intake",
      queryParameters: {"limit": limit, "cursor": ?cursor},
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "/api/v1/mail-messages/$mailId/resolve",
      // The server rejects unknown fields; null optionals are omitted.
      data: {
        for (final entry in body.entries)
          if (entry.value != null) entry.key: entry.value,
      },
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
        throw const MailIntakeApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
      }
      try {
        final response = await request({
          "Authorization": "Bearer $token",
          "Idempotency-Key": ?idempotencyKey,
        });
        final body = response.data;
        if (body == null) {
          throw const MailIntakeApiException(
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
    throw const MailIntakeApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");
  }

  static MailIntakeApiException _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const MailIntakeApiException(
        0,
        "NETWORK_UNAVAILABLE",
        "서버에 연결하지 못했어요.",
        unknownOutcome: true,
      );
    }
    final data = response.data;
    final detail = data is Map<String, dynamic> ? data["error"] : null;
    final status = response.statusCode ?? 0;
    return MailIntakeApiException(
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
