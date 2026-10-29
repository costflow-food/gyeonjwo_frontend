/// Temporary app models for SCR-007; independent of the mail_drafts schema.
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

/// Action codes from 08 that apply to drafts.
abstract final class DraftAction {
  static const edit = "EDIT_DRAFT";
  static const approveSend = "APPROVE_SEND";
  static const reconcile = "RECONCILE_SEND";
}

class DisabledDraftAction {
  const DisabledDraftAction({
    required this.action,
    required this.reasonCode,
    required this.message,
  });

  final String action;
  final String reasonCode;
  final String message;
}

class MailDraft {
  const MailDraft({
    required this.id,
    required this.caseId,
    required this.supplierName,
    required this.purpose,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.status,
    required this.approvalRequired,
    required this.inputRevision,
    required this.snapshotHash,
    required this.settingsVersion,
    required this.evidence,
    required this.allowedActions,
    required this.disabledActions,
    this.replacesId,
    this.sentAt,
    this.providerMessageId,
    this.failureMessage,
    this.settingsConfigured = true,
    this.autoSendAllowed = true,
  });

  final String id;
  final String caseId;
  final String supplierName;
  final DraftPurpose purpose;
  final String recipient;
  final String subject;
  final String body;
  final DraftStatus status;

  /// Effective send policy: true = approval ON, false = automatic (OFF).
  final bool approvalRequired;
  final bool settingsConfigured;
  final bool autoSendAllowed;
  final int inputRevision;
  final String snapshotHash;
  final int settingsVersion;

  /// Short lines that say which quote or condition the text relies on.
  final List<String> evidence;
  final List<String> allowedActions;
  final List<DisabledDraftAction> disabledActions;
  final String? replacesId;

  /// UTC ISO 8601.
  final String? sentAt;
  final String? providerMessageId;
  final String? failureMessage;

  bool can(String action) => allowedActions.contains(action);

  String? disabledReason(String action) => disabledActions
      .where((disabled) => disabled.action == action)
      .firstOrNull
      ?.message;
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
  const MailDraftFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => "MailDraftFailure($code)";
}
