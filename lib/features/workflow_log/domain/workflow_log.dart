/// Temporary app models for SCR-010; independent of the workflow_logs schema.
library;

/// Who produced the entry. Agent runs and case status are different things.
enum LogComponent {
  agent("AGENT", "에이전트"),
  node("NODE", "노드"),
  tool("TOOL", "도구"),
  user("USER", "구매담당자"),
  system("SYSTEM", "시스템");

  const LogComponent(this.code, this.label);
  final String code;
  final String label;

  static LogComponent fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => LogComponent.system,
  );
}

/// Five agent roles and the lightweight nodes from 07.
enum LogActor {
  extraction("EXTRACTION", "① 정보 추출"),
  candidate("CANDIDATE_SELECTION", "② 후보 선정"),
  priority("CLARIFICATION_PRIORITY", "③ 확인 우선순위"),
  responsePlan("RESPONSE_PLAN", "④ 대응안 생성"),
  counterOffer("COUNTER_OFFER", "⑤ 역제안 생성"),
  classifier("MAIL_CLASSIFIER", "경량 분류 노드"),
  validator("CODE_VALIDATOR", "코드 검증 노드"),
  dispatch("MAIL_DISPATCH", "메일 발송 노드"),
  receiver("MAIL_RECEIVER", "메일 수신기"),
  user("USER", "구매담당자");

  const LogActor(this.code, this.label);
  final String code;
  final String label;

  static LogActor fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => LogActor.receiver,
  );
}

enum LogEventType {
  mailReceived("MAIL_RECEIVED", "메일 수신"),
  classified("MAIL_CLASSIFIED", "분류"),
  reviewStarted("REVIEW_STARTED", "검토 시작"),
  agentRun("AGENT_RUN", "역할 실행"),
  toolCall("TOOL_CALL", "도구 호출"),
  draftCreated("DRAFT_CREATED", "초안 생성"),
  sendApproved("SEND_APPROVED", "승인 발송"),
  autoSent("AUTO_SENT", "자동 발송"),
  sendResult("SEND_RESULT", "발송 결과"),
  settingsChanged("SETTINGS_CHANGED", "설정 변경"),
  reviewCreated("REVIEW_CREATED", "검토 카드 생성");

  const LogEventType(this.code, this.label);
  final String code;
  final String label;

  static LogEventType fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => LogEventType.agentRun,
  );
}

enum LogOutcome {
  success("SUCCESS", "성공"),
  failure("FAILURE", "실패"),
  waiting("WAITING", "대기");

  const LogOutcome(this.code, this.label);
  final String code;
  final String label;

  static LogOutcome fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => LogOutcome.waiting,
  );
}

/// Whether a send went out after approval (ON) or by settings (OFF).
enum SendPolicy {
  approval("APPROVAL", "승인 발송"),
  automatic("AUTOMATIC", "자동 발송");

  const SendPolicy(this.code, this.label);
  final String code;
  final String label;

  static SendPolicy? fromCode(String? code) =>
      values.where((value) => value.code == code).firstOrNull;
}

class WorkflowLogEntry {
  const WorkflowLogEntry({
    required this.id,
    required this.createdAt,
    required this.component,
    required this.actor,
    required this.eventType,
    required this.summary,
    required this.outcome,
    required this.requestId,
    this.caseId,
    this.caseTitle,
    this.durationMs,
    this.runStatus,
    this.sendPolicy,
    this.evidenceRefs = const [],
    this.quoteVersion,
    this.settingsVersion,
    this.toolName,
    this.toolResultRef,
    this.errorCode,
    this.mailId,
    this.draftId,
  });

  final String id;

  /// UTC ISO 8601.
  final String createdAt;
  final LogComponent component;
  final LogActor actor;
  final LogEventType eventType;

  /// Short user-facing result. Never a private model reasoning trace.
  final String summary;
  final LogOutcome outcome;
  final String requestId;
  final String? caseId;
  final String? caseTitle;
  final int? durationMs;

  /// agent_runs status (RUNNING, COMPLETED, ...); not the case status.
  final String? runStatus;
  final SendPolicy? sendPolicy;
  final List<String> evidenceRefs;
  final int? quoteVersion;
  final int? settingsVersion;
  final String? toolName;
  final String? toolResultRef;
  final String? errorCode;
  final String? mailId;
  final String? draftId;
}

class WorkflowLogPage {
  const WorkflowLogPage({
    required this.items,
    required this.total,
    this.nextCursor,
  });

  final List<WorkflowLogEntry> items;
  final int total;
  final String? nextCursor;
}

class WorkflowLogFailure implements Exception {
  const WorkflowLogFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => "WorkflowLogFailure($code)";
}
