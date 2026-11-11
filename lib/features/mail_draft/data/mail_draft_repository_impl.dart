import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/idempotency_key.dart";
import "../../../shared/network/api_request.dart";

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

  /// API-16 pages of 100; a case has a few drafts per supplier and purpose.
  static const _maxPages = 5;

  final MailDraftDataSource _dataSource;
  final _keys = IdempotencyKeys();

  @override
  Future<List<MailDraft>> getDrafts(String caseId) => _guard(() async {
    final drafts = <MailDraft>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final response = await _dataSource.fetchDrafts(caseId, cursor: cursor);
      final data = response["data"] as Map<String, dynamic>;
      drafts.addAll([
        for (final entry in data["items"] as List)
          _draft(entry as Map<String, dynamic>),
      ]);
      cursor = data["next_cursor"] as String?;
      if (cursor == null) break;
    }
    return List.unmodifiable(drafts);
  });

  @override
  Future<MailDraft> getDraft(String draftId) => _guard(() async {
    final response = await _dataSource.fetchDraft(draftId);
    return _draft(response["data"] as Map<String, dynamic>);
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
  Future<void> approveAndSend(MailDraft draft) {
    final body = <String, Object?>{
      "expected_revision": draft.inputRevision,
      "snapshot_hash": draft.snapshotHash,
      // Opaque string from API-16·17, sent back unchanged.
      "expected_settings_version": draft.settingsVersion,
    };
    return _send("approve:${draft.id}", body, (key) async {
      _accepted(
        draft.id,
        await _dataSource.approveAndSend(draft.id, body, idempotencyKey: key),
      );
    });
  }

  @override
  Future<void> reconcile(MailDraft draft) =>
      _send("reconcile:${draft.id}", null, (key) async {
        _accepted(
          draft.id,
          await _dataSource.reconcile(draft.id, idempotencyKey: key),
        );
      });

  @override
  Future<void> withdraw(MailDraft draft, {required String reason}) {
    final body = <String, Object?>{
      "expected_revision": draft.inputRevision,
      "expected_snapshot_hash": draft.snapshotHash,
      "reason": reason,
    };
    // 200; the draft's new status comes from API-17.
    return _send("withdraw:${draft.id}", body, (key) async {
      await _dataSource.withdraw(draft.id, body, idempotencyKey: key);
    });
  }

  /// 202 only says the request was accepted; the result comes from API-17.
  static void _accepted(String draftId, Map<String, dynamic> response) {
    final data = response["data"] as Map<String, dynamic>;
    if (data["draft_id"] != draftId || data["accepted"] != true) {
      throw const MailDraftFailure(
        "INVALID_RESPONSE",
        "발송 요청 접수 결과를 확인하지 못했습니다.",
      );
    }
  }

  Future<T> _send<T>(
    String action,
    Object? body,
    Future<T> Function(String key) request,
  ) => _keys.run(
    action,
    body,
    (key) => _guard(() => request(key)),
    // Keep the key when the outcome is unknown so a retry cannot act twice.
    serverCode: (error) =>
        error is MailDraftFailure && !error.retryable ? error.code : null,
  );

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      throw MailDraftFailure(
        error.code,
        error.message,
        unknownOutcome: error.unknownOutcome,
        retryable: error.retryable,
      );
    }
  }

  static MailDraft _draft(Map<String, dynamic> json) {
    final policy = json["effective_send_policy"] as Map<String, dynamic>?;
    return MailDraft(
      id: json["draft_id"] as String,
      caseId: json["case_id"] as String,
      supplierId: json["supplier_id"] as String,
      purpose: DraftPurpose.fromCode(json["purpose"] as String),
      recipient: json["recipient"] as String,
      subject: json["subject"] as String,
      body: json["body_text"] as String,
      status: DraftStatus.fromCode(json["status"] as String),
      inputRevision: json["input_revision"] as int,
      snapshotHash: json["snapshot_hash"] as String,
      settingsConfigured: policy?["configured"] as bool? ?? false,
      approvalRequired: policy?["approval_required"] as bool?,
      settingsVersion: policy?["settings_version"] as String?,
      approvalAvailable: json["approval_available"] as bool?,
      autoPolicyEligible: json["auto_policy_eligible"] as bool?,
      blockReason: json["approval_block_reason"] as String?,
      isStale: json["is_stale"] as bool? ?? false,
      replacesId: json["replaces_id"] as String?,
      sentAt: json["sent_at"] as String?,
      providerMessageId: json["provider_message_id"] as String?,
    );
  }
}
