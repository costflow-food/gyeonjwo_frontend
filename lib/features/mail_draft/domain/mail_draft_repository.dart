import "mail_draft.dart";

/// Retries of the same action and body reuse one idempotency key.
abstract interface class MailDraftRepository {
  /// API-16. Latest draft per purpose and supplier for one case.
  Future<List<MailDraft>> getDrafts(String caseId);

  /// API-17. One draft's snapshot, effective policy, and send result.
  Future<MailDraft> getDraft(String draftId);

  /// API-18. Not on the server yet; the edit button stays disabled.
  Future<MailDraft> createRevision(MailDraft draft, DraftRevisionInput input);

  /// API-19. 202 means accepted, not sent; read API-17 for the result.
  Future<void> approveAndSend(MailDraft draft);

  /// API-20. 202 accepts a sent-folder check. Never re-sends.
  Future<void> reconcile(MailDraft draft);
}
