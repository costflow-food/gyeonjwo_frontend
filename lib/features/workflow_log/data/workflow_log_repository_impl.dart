import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/authorized_json_get.dart";
import "../domain/workflow_log.dart";
import "../domain/workflow_log_filter.dart";
import "../domain/workflow_log_repository.dart";
import "workflow_log_data_source.dart";

part "workflow_log_repository_impl.g.dart";

@Riverpod(keepAlive: true)
WorkflowLogRepository workflowLogRepository(Ref ref) {
  return WorkflowLogRepositoryImpl(ref.watch(workflowLogDataSourceProvider));
}

class WorkflowLogRepositoryImpl implements WorkflowLogRepository {
  const WorkflowLogRepositoryImpl(this._dataSource);

  final WorkflowLogDataSource _dataSource;

  @override
  Future<WorkflowLogPage> getLogs(
    WorkflowLogFilter filter, {
    String? cursor,
  }) async {
    final Map<String, dynamic> response;
    try {
      response = await _dataSource.fetchLogs(filter.toQuery(), cursor: cursor);
    } on ApiReadException catch (error) {
      throw WorkflowLogFailure(
        error.code ?? "HTTP_${error.statusCode}",
        error.message ?? "실행 로그를 불러오지 못했어요.",
      );
    }
    final data = response["data"] as Map<String, dynamic>;
    final items = [
      for (final entry in data["items"] as List)
        _entry(entry as Map<String, dynamic>),
    ];
    return WorkflowLogPage(
      items: List.unmodifiable(items),
      total:
          (data["counts"] as Map<String, dynamic>?)?["total"] as int? ??
          items.length,
      nextCursor: data["next_cursor"] as String?,
    );
  }

  static WorkflowLogEntry _entry(Map<String, dynamic> json) => WorkflowLogEntry(
    id: json["id"] as String,
    createdAt: json["created_at"] as String,
    componentCode: json["component_type"] as String?,
    actorCode: json["agent_role"] as String?,
    eventCode: json["event_type"] as String,
    summary: json["summary"] as String? ?? "",
    outcome: LogOutcome.fromCode(json["outcome"] as String?),
    requestId: json["request_id"] as String?,
    caseId: json["case_id"] as String?,
    caseTitle: json["case_title"] as String?,
    durationMs: json["duration_ms"] as int?,
    runStatus: json["run_status"] as String?,
    sendPolicy: SendPolicy.fromCode(json["send_policy"] as String?),
    evidenceRefs: List.unmodifiable(
      (json["evidence_refs"] as List? ?? const []).cast<String>(),
    ),
    quoteVersion: json["quote_version"] as int?,
    settingsVersion: json["settings_version"] as int?,
    toolName: json["tool_name"] as String?,
    toolResultRef: json["tool_result_ref"] as String?,
    errorCode: json["error_code"] as String?,
    mailId: json["mail_id"] as String?,
    draftId: json["draft_id"] as String?,
  );
}
