import "workflow_log.dart";
import "workflow_log_filter.dart";

abstract interface class WorkflowLogRepository {
  /// API-28, newest first (created_at DESC, id DESC).
  Future<WorkflowLogPage> getLogs(WorkflowLogFilter filter, {String? cursor});
}
