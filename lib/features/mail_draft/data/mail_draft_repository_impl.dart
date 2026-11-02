import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/idempotency_key.dart";

import "../domain/mail_draft.dart";
import "../domain/mail_draft_repository.dart";
import "mail_draft_data_source.dart";

part "mail_draft_repository_impl.g.dart";

@Riverpod(keepAlive: true)
MailDraftRepository mailDraftRepository(Ref ref) {
  return MailDraftRepositoryImpl(ref.watch(mailDraftDataSourceProvider));
}

class MailDraftRepositoryImpl implements MailDraftRepository {
  MailDraftRepositoryImpl(this._dataSource);

  final MailDraftDataSource _dataSource;
  final _keys = IdempotencyKeys();

  @override
  Future<List<MailDraft>> getDrafts(String caseId) => _guard(() async {
    final response = await _dataSource.fetchDrafts(caseId);
    final data = response["data"] as Map<String, dynamic>;
    return List.unmodifiable([
      for (final entry in data["items"] as List)
        _draft(entry as Map<String, dynamic>),
    ]);
  });

  @override
  Future<MailDraft> createRevision(MailDraft draft, DraftRevisionInput input) {
    final body = <String, Object?>{
      "expected_revision": draft.inputRevision,
      "expected_snapshot_hash": draft.snapshotHash,
      "recipient": input.recipient,
      "subject": input.subject,
      "body_text": input.body,
      "edit_reason": input.editReason,
    };
    return _send("revise:${draft.id}", body, (key) async {
      final response = await _dataSource.createRevision(
        draft.id,
        body,
        idempotencyKey: key,
      );
      return _draft(response["data"] as Map<String, dynamic>);
    });
  }

  @override
  Future<MailDraft> approveAndSend(MailDraft draft) {
    final body = <String, Object?>{
      "expected_revision": draft.inputRevision,
      "snapshot_hash": draft.snapshotHash,
      "expected_settings_version": draft.settingsVersion,
    };
    return _send("approve:${draft.id}", body, (key) async {
      final response = await _dataSource.approveAndSend(
        draft.id,
        body,
        idempotencyKey: key,
      );
      return _draft(response["data"] as Map<String, dynamic>);
    });
  }

  @override
  Future<MailDraft> reconcile(MailDraft draft) =>
      _send("reconcile:${draft.id}", null, (key) async {
        final response = await _dataSource.reconcile(
          draft.id,
          idempotencyKey: key,
        );
        return _draft(response["data"] as Map<String, dynamic>);
      });

  Future<MailDraft> _send(
    String action,
    Object? body,
    Future<MailDraft> Function(String key) request,
  ) => _keys.run(
    action,
    body,
    (key) => _guard(() => request(key)),
    serverCode: (error) => error is MailDraftFailure ? error.code : null,
  );

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on MailDraftApiException catch (error) {
      throw MailDraftFailure(error.code, error.message);
    }
  }

  static MailDraft _draft(Map<String, dynamic> json) => MailDraft(
    id: json["draft_id"] as String,
    caseId: json["case_id"] as String,
    supplierName: json["supplier_name"] as String,
    purpose: DraftPurpose.fromCode(json["purpose"] as String),
    recipient: json["recipient"] as String,
    subject: json["subject"] as String,
    body: json["body_text"] as String,
    status: DraftStatus.fromCode(json["status"] as String),
    approvalRequired: json["approval_required"] as bool,
    settingsConfigured: json['settings_configured'] as bool? ?? true,
    autoSendAllowed: json['auto_send_allowed'] as bool? ?? true,
    inputRevision: json["input_revision"] as int,
    snapshotHash: json["snapshot_hash"] as String,
    settingsVersion: json["settings_version"] as int,
    evidence: List.unmodifiable((json["evidence"] as List).cast<String>()),
    allowedActions: List.unmodifiable(
      (json["allowed_actions"] as List).cast<String>(),
    ),
    disabledActions: List.unmodifiable([
      for (final entry in json["disabled_actions"] as List)
        DisabledDraftAction(
          action: entry["action"] as String,
          reasonCode: entry["reason_code"] as String,
          message: entry["message"] as String,
        ),
    ]),
    replacesId: json["replaces_id"] as String?,
    sentAt: json["sent_at"] as String?,
    providerMessageId: json["provider_message_id"] as String?,
    failureMessage: json["failure_message"] as String?,
  );
}
