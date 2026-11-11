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

  /// Null for a code this app does not know yet; the raw code is shown.
  static LogComponent? fromCode(String? code) =>
      values.where((value) => value.code == code).firstOrNull;
}

/// Five agent roles and the lightweight nodes from 07. [code] is the DB
/// agent_runs.agent_role (06); [aliases] are earlier app codes, still accepted.
enum LogActor {
  extraction("INFO_EXTRACTOR", "① 정보 추출", ["EXTRACTION"]),
  candidate("CANDIDATE", "② 후보 선정", ["CANDIDATE_SELECTION"]),
  priority("INFO_PRIORITY", "③ 확인 우선순위", ["CLARIFICATION_PRIORITY"]),
  responsePlan("RESPONSE_PLAN", "④ 대응안 생성"),
  counterOffer("COUNTER_OFFER", "⑤ 역제안 생성"),
  classifier("LIGHT_CLASSIFIER", "경량 분류 노드", ["MAIL_CLASSIFIER"]),
  validator("CODE_VALIDATOR", "코드 검증 노드"),
  dispatch("MAIL_DISPATCH", "메일 발송 노드"),
  receiver("MAIL_RECEIVER", "메일 수신기"),
  user("USER", "구매담당자");

  const LogActor(this.code, this.label, [this.aliases = const []]);
  final String code;
  final String label;
  final List<String> aliases;

  /// Null for a code this app does not know yet; the raw code is shown.
  static LogActor? fromCode(String? code) => values
      .where((value) => value.code == code || value.aliases.contains(code))
      .firstOrNull;
}

/// workflow_logs.event_type. The DB codes (06 list and what the graph
/// writes) come first; the rest are earlier app codes.
enum LogEventType {
  groupLinked("GROUP_LINKED", "업무 묶음 연결"),
  mailAcknowledged("MAIL_ACKNOWLEDGED", "메일 확인"),
  reviewRequested("REVIEW_REQUESTED", "검토 요청"),
  reviewStepChanged("REVIEW_STEP_CHANGED", "진행 단계 변경"),
  roleStarted("GRAPH_ROLE_STARTED", "역할 실행 시작"),
  roleFinished("GRAPH_ROLE_FINISHED", "역할 실행 완료"),
  graphCompleted("GRAPH_COMPLETED", "검토 실행 완료"),
  graphFailed("GRAPH_FAILED", "검토 실행 실패"),
  quoteStored("QUOTE_STORED", "견적 저장"),
  rfqIntakeLinked("RFQ_INTAKE_LINKED", "회신 연결"),
  hold("HOLD", "보류"),
  resume("RESUME", "재개"),
  acceptIncrease("ACCEPT_INCREASE", "수용"),
  archive("ARCHIVE", "보관"),
  restore("RESTORE", "복원"),
  approvalRequired("APPROVAL_REQUIRED", "승인 필요"),
  draftApproved("DRAFT_APPROVED", "초안 승인"),
  approved("APPROVED", "발송 승인"),
  autoSendAuthorized("AUTO_SEND_AUTHORIZED", "자동 발송 허용"),
  rfqDispatchRequested("RFQ_DISPATCH_REQUESTED", "발송 요청"),
  sent("SENT", "발송됨"),
  failed("FAILED", "실패"),
  sendUnknown("SEND_UNKNOWN", "발송 결과 확인 필요"),
  reviewCreated("REVIEW_CREATED", "검토 카드 생성"),
  planSelected("PLAN_SELECTED", "구매안 선택"),
  selectionInvalidated("SELECTION_INVALIDATED", "선택 무효"),
  mailReceived("MAIL_RECEIVED", "메일 수신"),
  classified("MAIL_CLASSIFIED", "분류"),
  reviewStarted("REVIEW_STARTED", "검토 시작"),
  agentRun("AGENT_RUN", "역할 실행"),
  toolCall("TOOL_CALL", "도구 호출"),
  draftCreated("DRAFT_CREATED", "초안 생성"),
  sendApproved("SEND_APPROVED", "승인 발송"),
  autoSent("AUTO_SENT", "자동 발송"),
  sendResult("SEND_RESULT", "발송 결과"),
  settingsChanged("SETTINGS_CHANGED", "설정 변경");

  const LogEventType(this.code, this.label);
  final String code;
  final String label;

  /// Null for a code this app does not know yet; the raw code is shown.
  static LogEventType? fromCode(String? code) =>
      values.where((value) => value.code == code).firstOrNull;
}

enum LogOutcome {
  success("SUCCESS", "성공"),
  failure("FAILURE", "실패"),
  waiting("WAITING", "대기");

  const LogOutcome(this.code, this.label);
  final String code;
  final String label;

  /// Null for a code this app does not know yet; the raw code is shown.
  static LogOutcome? fromCode(String? code) =>
      values.where((value) => value.code == code).firstOrNull;
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
    required this.componentCode,
    required this.actorCode,
    required this.eventCode,
    this.summary = "",
    this.outcome,
    this.requestId,
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

  /// Raw `component_type`, `agent_role`, `event_type`. New server codes stay
  /// visible as-is instead of being shown under a wrong label.
  final String? componentCode;
  final String? actorCode;
  final String eventCode;

  /// Short user-facing result. Never a private model reasoning trace.
  final String summary;

  /// Null when the server does not report a result for the event.
  final LogOutcome? outcome;
  final String? requestId;
  final String? caseId;

  /// The case's item name. Null while the item is not identified yet, even
  /// though the case exists.
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

  LogComponent? get component => LogComponent.fromCode(componentCode);
  LogActor? get actor => LogActor.fromCode(actorCode);
  LogEventType? get eventType => LogEventType.fromCode(eventCode);

  String get eventLabel => eventType?.label ?? eventCode;

  /// Case name for display. A log written before any case exists and a log of
  /// a case whose item is not identified yet are different states.
  String get caseLabel =>
      caseTitle ?? (caseId == null ? "업무 없음 (접수 단계)" : "품목 미확인 업무");

  /// "① 정보 추출 (에이전트)" style; whichever part is known.
  String get actorLabel {
    final actorText = actor?.label ?? actorCode;
    final componentText = component?.label ?? componentCode;
    if (actorText == null) return componentText ?? "미확인";
    return componentText == null ? actorText : "$actorText ($componentText)";
  }
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
