import "../../mail_draft/domain/mail_draft.dart";

/// Temporary app models for SCR-008; independent of mail_send_settings.
enum SettingSource {
  caseLevel("CASE", "이 업무 설정"),
  mailbox("MAILBOX", "메일함 기본값");

  const SettingSource(this.code, this.label);
  final String code;
  final String label;

  static SettingSource? fromCode(String? code) =>
      values.where((value) => value.code == code).firstOrNull;
}

enum MailTone {
  formal("FORMAL", "격식체"),
  friendly("FRIENDLY", "부드러운 존댓말");

  const MailTone(this.code, this.label);
  final String code;
  final String label;

  static MailTone fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => MailTone.formal,
  );
}

/// Effective approval for one purpose. null means not set (inherited or
/// missing); false is an explicit OFF.
class PurposeApproval {
  const PurposeApproval({
    required this.purpose,
    required this.ownValue,
    required this.effectiveValue,
    this.source,
    this.sourceVersion,
  });

  final DraftPurpose purpose;

  /// Value stored at this scope; null inherits from the mailbox default.
  final bool? ownValue;

  /// Value after inheritance; null means still not configured.
  final bool? effectiveValue;
  final SettingSource? source;
  final int? sourceVersion;
}

class SendSettings {
  const SendSettings({
    required this.mailboxRef,
    required this.configured,
    required this.settingsVersion,
    required this.approvals,
    required this.missingItems,
    required this.tone,
    required this.signature,
    this.caseId,
  });

  final String mailboxRef;
  final String? caseId;
  final bool configured;
  final int settingsVersion;
  final List<PurposeApproval> approvals;
  final List<String> missingItems;
  final MailTone tone;
  final String signature;

  bool get isCaseScope => caseId != null;
}

/// API-22 body. Auto-send is set per purpose only; who receives the mail
/// comes from the case's candidate selection (API-12), not from these
/// settings. Saves always apply to future drafts.
class SendSettingsUpdate {
  const SendSettingsUpdate({
    required this.mailboxRef,
    required this.expectedSettingsVersion,
    required this.approvalByPurpose,
    required this.tone,
    required this.signature,
  });

  /// The mailbox_ref the loaded settings came with.
  final String mailboxRef;
  final int expectedSettingsVersion;
  final Map<DraftPurpose, bool?> approvalByPurpose;
  final MailTone tone;
  final String signature;
}

class SendSettingsFailure implements Exception {
  const SendSettingsFailure(
    this.code,
    this.message, {
    this.unknownOutcome = false,
    this.retryable = false,
  });
  final String code;
  final String message;

  /// No response arrived; the server may or may not have saved.
  final bool unknownOutcome;

  /// 응답 없음·5xx·`retryable: true`: 서버가 처리했을 수 있어 같은 멱등 키를
  /// 남기고 상태를 다시 읽습니다. [unknownOutcome]이면 늘 참입니다.
  final bool retryable;

  /// Someone saved a newer version; reload before deciding again.
  bool get settingsChanged => code == "SETTINGS_CHANGED";

  @override
  String toString() => "SendSettingsFailure($code)";
}
