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

enum ApplyTo { futureDrafts, specifiedDrafts }

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

class AllowedSupplier {
  const AllowedSupplier({
    required this.id,
    required this.name,
    required this.allowed,
    this.email,
  });

  final String id;
  final String name;
  final String? email;
  final bool allowed;
}

/// Existing draft that a save could also apply to.
class PendingDraft {
  const PendingDraft({
    required this.draftId,
    required this.purpose,
    required this.supplierName,
    required this.recipient,
    required this.status,
  });

  final String draftId;
  final DraftPurpose purpose;
  final String supplierName;
  final String recipient;
  final DraftStatus status;

  /// SENDING, SENT, and UNKNOWN drafts never change settings retroactively.
  bool get selectable => status == DraftStatus.draft;
}

class SendSettings {
  const SendSettings({
    required this.mailboxRef,
    required this.configured,
    required this.settingsVersion,
    required this.approvals,
    required this.missingItems,
    required this.suppliers,
    required this.tone,
    required this.signature,
    required this.pendingDrafts,
    this.caseId,
  });

  final String mailboxRef;
  final String? caseId;
  final bool configured;
  final int settingsVersion;
  final List<PurposeApproval> approvals;
  final List<String> missingItems;
  final List<AllowedSupplier> suppliers;
  final MailTone tone;
  final String signature;
  final List<PendingDraft> pendingDrafts;

  bool get isCaseScope => caseId != null;
}

/// API-22 body.
class SendSettingsUpdate {
  const SendSettingsUpdate({
    required this.expectedSettingsVersion,
    required this.approvalByPurpose,
    required this.allowedSupplierIds,
    required this.tone,
    required this.signature,
    required this.applyTo,
    required this.draftIds,
  });

  final int expectedSettingsVersion;
  final Map<DraftPurpose, bool?> approvalByPurpose;
  final List<String> allowedSupplierIds;
  final MailTone tone;
  final String signature;
  final ApplyTo applyTo;
  final List<String> draftIds;
}

class SendSettingsFailure implements Exception {
  const SendSettingsFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => "SendSettingsFailure($code)";
}
