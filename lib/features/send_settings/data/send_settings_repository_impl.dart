import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../mail_draft/domain/mail_draft.dart";
import "../domain/send_settings.dart";
import "../domain/send_settings_repository.dart";
import "send_settings_data_source.dart";

part "send_settings_repository_impl.g.dart";

@Riverpod(keepAlive: true)
SendSettingsRepository sendSettingsRepository(Ref ref) {
  return SendSettingsRepositoryImpl(ref.watch(sendSettingsDataSourceProvider));
}

class SendSettingsRepositoryImpl implements SendSettingsRepository {
  const SendSettingsRepositoryImpl(this._dataSource);

  final SendSettingsDataSource _dataSource;

  @override
  Future<SendSettings> getSettings({String? caseId}) => _guard(() async {
    final response = await _dataSource.fetchSettings(caseId: caseId);
    return _settings(response["data"] as Map<String, dynamic>);
  });

  @override
  Future<SendSettings> saveSettings(
    SendSettingsUpdate update, {
    String? caseId,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _dataSource.saveSettings({
      "mailbox_ref": "demo-purchase-mailbox",
      "case_id": caseId,
      "expected_settings_version": update.expectedSettingsVersion,
      "approval_required_by_purpose": {
        for (final entry in update.approvalByPurpose.entries)
          entry.key.code: entry.value,
      },
      "allowed_supplier_ids": update.allowedSupplierIds,
      "style": {"tone": update.tone.code, "signature": update.signature},
      "apply_to": switch (update.applyTo) {
        ApplyTo.futureDrafts => "FUTURE_DRAFTS",
        ApplyTo.specifiedDrafts => "SPECIFIED_DRAFTS",
      },
      "draft_ids": update.draftIds,
    }, idempotencyKey: idempotencyKey);
    return _settings(response["data"] as Map<String, dynamic>);
  });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SendSettingsApiException catch (error) {
      throw SendSettingsFailure(error.code, error.message);
    }
  }

  static SendSettings _settings(Map<String, dynamic> json) {
    final effective = json["effective_settings"] as Map<String, dynamic>;
    final style = json["style"] as Map<String, dynamic>;
    return SendSettings(
      mailboxRef: json["mailbox_ref"] as String,
      caseId: json["case_id"] as String?,
      configured: json["configured"] as bool,
      settingsVersion: json["settings_version"] as int,
      missingItems: List.unmodifiable(
        (json["missing_items"] as List).cast<String>(),
      ),
      approvals: List.unmodifiable([
        for (final purpose in DraftPurpose.values)
          _approval(purpose, effective[purpose.code] as Map<String, dynamic>),
      ]),
      suppliers: List.unmodifiable([
        for (final entry in json["allowed_suppliers"] as List)
          AllowedSupplier(
            id: entry["supplier_id"] as String,
            name: entry["name"] as String,
            email: entry["email"] as String?,
            allowed: entry["allowed"] as bool,
          ),
      ]),
      tone: MailTone.fromCode(style["tone"] as String),
      signature: style["signature"] as String? ?? "",
      pendingDrafts: List.unmodifiable([
        for (final entry in json["pending_drafts"] as List)
          PendingDraft(
            draftId: entry["draft_id"] as String,
            purpose: DraftPurpose.fromCode(entry["purpose"] as String),
            supplierName: entry["supplier_name"] as String,
            recipient: entry["recipient"] as String,
            status: DraftStatus.fromCode(entry["status"] as String),
          ),
      ]),
    );
  }

  static PurposeApproval _approval(
    DraftPurpose purpose,
    Map<String, dynamic> json,
  ) => PurposeApproval(
    purpose: purpose,
    ownValue: json["approval_required"] as bool?,
    effectiveValue: json["effective_approval_required"] as bool?,
    source: SettingSource.fromCode(json["source"] as String?),
    sourceVersion: json["source_version"] as int?,
  );
}
