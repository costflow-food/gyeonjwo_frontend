import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/idempotency_key.dart";

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
  SendSettingsRepositoryImpl(this._dataSource);

  final SendSettingsDataSource _dataSource;
  final _keys = IdempotencyKeys();

  @override
  Future<SendSettings> getSettings({String? caseId}) => _guard(() async {
    final response = await _dataSource.fetchSettings(caseId: caseId);
    return _settings(response["data"] as Map<String, dynamic>);
  });

  @override
  Future<SendSettings> saveSettings(
    SendSettingsUpdate update, {
    String? caseId,
  }) {
    final body = <String, Object?>{
      // Echo the GET response value; the server has no mailbox alias.
      "mailbox_ref": update.mailboxRef,
      "case_id": caseId,
      "expected_settings_version": update.expectedSettingsVersion,
      "approval_required_by_purpose": {
        for (final entry in update.approvalByPurpose.entries)
          entry.key.code: entry.value,
      },
      // No per-supplier allow list. The server ignores this field, but a
      // server built before it became optional still requires the key.
      "allowed_supplier_ids": const <String>[],
      "style": {"tone": update.tone.code, "signature": update.signature},
      // The server stores only FUTURE_DRAFTS for now.
      "apply_to": "FUTURE_DRAFTS",
      "draft_ids": const <String>[],
    };
    return _keys.run(
      "save:${caseId ?? "mailbox"}",
      body,
      (key) => _guard(() async {
        final response = await _dataSource.saveSettings(
          body,
          idempotencyKey: key,
        );
        return _settings(response["data"] as Map<String, dynamic>);
      }),
      // Keep the key when the outcome is unknown so a retry cannot save twice.
      serverCode: (error) =>
          error is SendSettingsFailure && !error.unknownOutcome
          ? error.code
          : null,
    );
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SendSettingsApiException catch (error) {
      throw SendSettingsFailure(
        error.code,
        error.message,
        unknownOutcome: error.unknownOutcome,
      );
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
      tone: MailTone.fromCode(style["tone"] as String),
      signature: style["signature"] as String? ?? "",
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
