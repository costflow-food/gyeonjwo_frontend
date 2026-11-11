/// SCR-007 models for API-16·17·19·20.
library;

enum DraftPurpose {
  rfq("RFQ", "견적 요청"),
  clarification("CLARIFICATION", "추가 확인"),
  counterOffer("COUNTER_OFFER", "역제안");

  const DraftPurpose(this.code, this.label);
  final String code;
  final String label;

  static DraftPurpose fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () =>
        throw MailDraftFailure("UNKNOWN_PURPOSE", "알 수 없는 초안 목적입니다: $code"),
  );
}

/// DRAFT → SENDING → SENT / FAILED / UNKNOWN. UNKNOWN may already be sent.
enum DraftStatus {
  draft("DRAFT", "초안"),
  sending("SENDING", "발송 중"),
  sent("SENT", "발송됨"),
  failed("FAILED", "발송 실패"),
  unknown("UNKNOWN", "발송 확인 중");

  const DraftStatus(this.code, this.label);
  final String code;
  final String label;

  /// Unknown codes fall back to UNKNOWN, which blocks edits and re-sends.
  static DraftStatus fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => DraftStatus.unknown,
  );
}

/// Draft actions. API-16·17 send no allowed_actions, so [MailDraft] derives
/// them from status and the effective send policy, as the server checks them.
abstract final class DraftAction {
  static const edit = "EDIT_DRAFT";
  static const approveSend = "APPROVE_SEND";
  static const reconcile = "RECONCILE_SEND";

  /// 보내지 않은 초안을 닫습니다. 남은 초안이 다음 후보 선택·검토 완료를 막지 않게 합니다.
  static const withdraw = "WITHDRAW_DRAFT";
}

/// API-16·17 approval_block_reason.
abstract final class DraftBlockReason {
  static const settingsRequired = "SEND_SETTINGS_REQUIRED";
  static const recipientNotRegistered = "RECIPIENT_NOT_REGISTERED";
}

/// API-12 drafts[].dispatch_state: what happened to each selected supplier.
enum DraftDispatchState {
  waitingApproval("WAITING_APPROVAL", "승인 대기", "승인 후 발송을 눌러야 발송돼요."),
  autoQueued("AUTO_QUEUED", "자동 발송 대기", "자동 발송이 켜져 있어 서버가 자동 발송해요."),
  cautionRequired(
    "CAUTION_REQUIRED",
    "주의 필요",
    "확인할 점이 있어 자동 발송하지 않았어요. 내용을 확인한 뒤 승인해 주세요.",
  ),
  blockedPolicy(
    "BLOCKED_POLICY",
    "정책상 차단",
    "발송 설정이 끝나지 않았거나 받는 주소가 등록된 업체 주소와 달라 발송하지 않아요.",
  );

  const DraftDispatchState(this.code, this.label, this.message);
  final String code;
  final String label;
  final String message;

  static DraftDispatchState? fromCode(String? code) =>
      values.where((value) => value.code == code).firstOrNull;

  /// Lower is more urgent; the draft screen opens on the most urgent one.
  int get priority => switch (this) {
    waitingApproval => 0,
    cautionRequired => 1,
    blockedPolicy => 2,
    autoQueued => 3,
  };
}

/// API-16·17 draft. The response has no supplier name, evidence, failure
/// reason, or action lists; the name comes from the API-11 candidates.
class MailDraft {
  const MailDraft({
    required this.id,
    required this.caseId,
    required this.supplierId,
    required this.purpose,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.status,
    required this.inputRevision,
    required this.snapshotHash,
    required this.settingsConfigured,
    this.approvalRequired,
    this.settingsVersion,
    this.approvalAvailable,
    this.autoPolicyEligible,
    this.blockReason,
    this.isStale = false,
    this.supplierName,
    this.replacesId,
    this.sentAt,
    this.providerMessageId,
    this.awaitingResult = false,
    this.resultTimedOut = false,
  });

  final String id;
  final String caseId;
  final String supplierId;
  final DraftPurpose purpose;
  final String recipient;
  final String subject;
  final String body;
  final DraftStatus status;
  final int inputRevision;
  final String snapshotHash;

  /// effective_send_policy. approvalRequired is null until configured.
  final bool settingsConfigured;
  final bool? approvalRequired;

  /// Opaque version from the server; sent back unchanged on approval.
  final String? settingsVersion;

  /// KAN-167 S4-4 (API-16·17). Null on servers that do not send it yet.
  /// With approval OFF, a draft the server will not auto-send (chosen before
  /// the settings were saved, or a caution supplier) still needs approval.
  final bool? approvalAvailable;
  final bool? autoPolicyEligible;

  /// SEND_SETTINGS_REQUIRED or RECIPIENT_NOT_REGISTERED when sending is blocked.
  final String? blockReason;

  bool get needsSettings =>
      blockReason == DraftBlockReason.settingsRequired ||
      (blockReason == null && !settingsConfigured);

  bool get recipientNotRegistered =>
      blockReason == DraftBlockReason.recipientNotRegistered;

  /// Approval OFF, yet this draft waits for a manual approval.
  bool get manualApprovalUnderAutoSend =>
      approvalRequired == false && approvalAvailable == true;

  /// The case input changed after this draft was written.
  final bool isStale;

  /// From the API-11 candidates; null when they are not available.
  final String? supplierName;
  final String? replacesId;

  /// UTC ISO 8601.
  final String? sentAt;
  final String? providerMessageId;

  /// App-only: an approval or reconcile was accepted (202) and the result
  /// is not visible in API-17 yet.
  final bool awaitingResult;

  /// App-only: the accepted request showed no result within the wait, so it
  /// may not have been carried out.
  final bool resultTimedOut;

  String get displayName => supplierName ?? recipient;

  MailDraft copyWith({
    String? supplierName,
    bool? awaitingResult,
    bool? resultTimedOut,
  }) => MailDraft(
    id: id,
    caseId: caseId,
    supplierId: supplierId,
    purpose: purpose,
    recipient: recipient,
    subject: subject,
    body: body,
    status: status,
    inputRevision: inputRevision,
    snapshotHash: snapshotHash,
    settingsConfigured: settingsConfigured,
    approvalRequired: approvalRequired,
    settingsVersion: settingsVersion,
    approvalAvailable: approvalAvailable,
    autoPolicyEligible: autoPolicyEligible,
    blockReason: blockReason,
    isStale: isStale,
    supplierName: supplierName ?? this.supplierName,
    replacesId: replacesId,
    sentAt: sentAt,
    providerMessageId: providerMessageId,
    awaitingResult: awaitingResult ?? this.awaitingResult,
    resultTimedOut: resultTimedOut ?? this.resultTimedOut,
  );

  bool can(String action) => switch (action) {
    DraftAction.approveSend =>
      status == DraftStatus.draft &&
          settingsConfigured &&
          // The server decides when it sends approval_available; older
          // servers only allow approval with the setting ON.
          (approvalAvailable ?? approvalRequired == true) &&
          settingsVersion != null &&
          !isStale &&
          !awaitingResult,
    DraftAction.reconcile => status == DraftStatus.unknown && !awaitingResult,
    DraftAction.withdraw => status == DraftStatus.draft && !awaitingResult,
    // API-18 (revisions) does not exist on the server yet.
    _ => false,
  };

  String? disabledReason(String action) => switch (action) {
    DraftAction.edit => "초안 수정은 서버에 수정본 저장 기능이 생기면 열려요.",
    DraftAction.approveSend when status != DraftStatus.draft => null,
    DraftAction.approveSend when awaitingResult =>
      "발송 요청을 접수했어요. 결과를 확인하고 있어요.",
    DraftAction.approveSend when recipientNotRegistered =>
      "받는 주소가 등록된 업체 주소와 달라 발송할 수 없어요.",
    DraftAction.approveSend when !settingsConfigured =>
      "설정 → 메일 발송 설정을 완료해야 발송할 수 있어요.",
    DraftAction.approveSend when isStale => "업무 내용이 바뀌어 이 초안은 발송할 수 없어요.",
    DraftAction.approveSend
        when approvalRequired == false && approvalAvailable != true =>
      "자동 발송이 켜져 있어 서버가 검증한 뒤 자동 발송해요.",
    DraftAction.approveSend when settingsVersion == null =>
      "발송 설정 버전을 확인할 수 없어요. 다시 불러와 주세요.",
    DraftAction.reconcile when awaitingResult => "발신함 대조를 접수했어요. 결과를 확인하고 있어요.",
    _ => null,
  };
}

/// API-18 body. A revision is a new draft; earlier approval is not reused.
class DraftRevisionInput {
  const DraftRevisionInput({
    required this.recipient,
    required this.subject,
    required this.body,
    this.editReason,
  });

  final String recipient;
  final String subject;
  final String body;
  final String? editReason;
}

class MailDraftFailure implements Exception {
  const MailDraftFailure(
    this.code,
    this.message, {
    this.unknownOutcome = false,
    this.retryable = false,
  });
  final String code;
  final String message;

  /// No response arrived; the server may or may not have accepted it.
  final bool unknownOutcome;

  /// 응답 없음·5xx·`retryable: true`: 서버가 처리했을 수 있어 같은 멱등 키를
  /// 남기고 상태를 다시 읽습니다. [unknownOutcome]이면 늘 참입니다.
  final bool retryable;

  /// The draft, its case, or the settings changed; reload before deciding.
  bool get draftChanged => const {
    "DRAFT_CHANGED",
    "REVISION_CONFLICT",
    "SETTINGS_CHANGED",
    "ACTION_NOT_ALLOWED",
    "SEND_RESULT_UNKNOWN",
  }.contains(code);

  @override
  String toString() => "MailDraftFailure($code)";
}
