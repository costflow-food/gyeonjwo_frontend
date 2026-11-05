import "dart:convert";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/authorized_json_get.dart";
import "../../auth/data/auth_session_data_source.dart";
import "workflow_log_preview_data.dart";

part "workflow_log_data_source.g.dart";

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
@Riverpod(keepAlive: true)
WorkflowLogDataSource workflowLogDataSource(Ref ref) =>
    ApiWorkflowLogDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-28 `GET /workflow-logs` with snake_case query parameters.
/// Failures use the 08 error shape via [ApiReadException].
abstract interface class WorkflowLogDataSource {
  Future<Map<String, dynamic>> fetchLogs(
    Map<String, String> query, {
    String? cursor,
    int limit = 25,
  });
}

class ApiWorkflowLogDataSource implements WorkflowLogDataSource {
  const ApiWorkflowLogDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final ApiTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchLogs(
    Map<String, String> query, {
    String? cursor,
    int limit = 25,
  }) => authorizedJsonGet(
    _dio,
    _accessToken,
    "/api/v1/workflow-logs",
    queryParameters: {...query, "cursor": ?cursor, "limit": limit},
  );
}

/// Filters the fixture the way the server would, for the UI preview page.
class PreviewWorkflowLogDataSource implements WorkflowLogDataSource {
  const PreviewWorkflowLogDataSource({
    this.latency = const Duration(milliseconds: 250),
  });

  final Duration latency;

  @override
  Future<Map<String, dynamic>> fetchLogs(
    Map<String, String> query, {
    String? cursor,
    int limit = 25,
  }) async {
    await Future<void>.delayed(latency);
    final matches = [
      for (final entry in workflowLogPreviewEntries)
        if (_matches(entry, query)) entry,
    ];
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, matches.length);
    return jsonDecode(
      jsonEncode({
        "data": {
          "items": matches.sublist(start, end),
          "next_cursor": end < matches.length ? "$end" : null,
          "counts": {"total": matches.length},
        },
        "meta": {"request_id": "req-preview-workflow-logs"},
      }),
    ) as Map<String, dynamic>;
  }

  static bool _matches(Map<String, Object?> entry, Map<String, String> query) =>
      query["case_id"] == null || entry["case_id"] == query["case_id"];
}
