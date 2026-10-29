import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "workflow_log_preview_data.dart";

part "workflow_log_data_source.g.dart";

@Riverpod(keepAlive: true)
WorkflowLogDataSource workflowLogDataSource(Ref ref) {
  return const PreviewWorkflowLogDataSource();
}

/// API-28 `GET /workflow-logs` with snake_case query parameters.
abstract interface class WorkflowLogDataSource {
  Future<Map<String, dynamic>> fetchLogs(
    Map<String, String> query, {
    String? cursor,
    int limit = 25,
  });
}

/// Filters the fixture the way the server would. Replace with Dio later.
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
    final keyword = query["q"]?.toLowerCase();
    final from = query["from"] == null ? null : DateTime.parse(query["from"]!);
    final matches = [
      for (final entry in workflowLogPreviewEntries)
        if (_matches(entry, query, keyword, from)) entry,
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
        )
        as Map<String, dynamic>;
  }

  static bool _matches(
    Map<String, Object?> entry,
    Map<String, String> query,
    String? keyword,
    DateTime? from,
  ) {
    bool equals(String key, String field) =>
        query[key] == null || entry[field] == query[key];
    final title = (entry["case_title"] as String?)?.toLowerCase() ?? "";
    final caseId = (entry["case_id"] as String?)?.toLowerCase() ?? "";
    final createdAt = DateTime.parse(entry["created_at"] as String);
    return equals("agent_role", "agent_role") &&
        equals("event_type", "event_type") &&
        equals("outcome", "outcome") &&
        equals("send_policy", "send_policy") &&
        (from == null || !createdAt.isBefore(from)) &&
        (keyword == null ||
            title.contains(keyword) ||
            caseId.contains(keyword));
  }
}
