import "mail_draft.dart";

/// Retries of the same action and body reuse one idempotency key.
abstract interface class MailDraftRepository {
  Future<List<MailDraft>> getDrafts(String caseId);

  Future<MailDraft> getDraft(String draftId);

  Future<MailDraft> createRevision(MailDraft draft, DraftRevisionInput input);

  /// API-19. 202 means accepted, not sent; read API-17 for the result.
  Future<void> approveAndSend(MailDraft draft);

  /// API-20. 202 accepts a sent-folder check. Never re-sends.
  Future<void> reconcile(MailDraft draft);

  Future<void> withdraw(MailDraft draft, {required String reason});
}
