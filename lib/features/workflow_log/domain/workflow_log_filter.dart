/// API-28 search condition. The screen only narrows to one case (`case_id`),
/// picked from a log entry; changing it restarts from page one.
class WorkflowLogFilter {
  const WorkflowLogFilter({this.caseId, this.caseTitle});

  final String? caseId;

  /// Display only; not sent to the server.
  final String? caseTitle;

  bool get isEmpty => caseId == null;

  /// Query parameters in the 08 snake_case form.
  Map<String, String> toQuery() => {"case_id": ?caseId};
}
