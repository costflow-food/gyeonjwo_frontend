import "mail_draft.dart";

/// Retries of the same action and body reuse one idempotency key.
abstract interface class MailDraftRepository {
  /// API-16. Latest draft per purpose and supplier for one case.
  Future<List<MailDraft>> getDrafts(String caseId);

  /// API-17. One draft's snapshot, effective policy, and send result.
  Future<MailDraft> getDraft(String draftId);

  /// API-18. Not reached from the screen: [MailDraft.can] keeps edit off.
  Future<MailDraft> createRevision(MailDraft draft, DraftRevisionInput input);

  /// API-19. 202 means accepted, not sent; read API-17 for the result.
  Future<void> approveAndSend(MailDraft draft);

  /// API-20. 202 accepts a sent-folder check. Never re-sends.
  Future<void> reconcile(MailDraft draft);

  /// `POST /mail-drafts/{draft_id}/withdraw`. Closes an unsent DRAFT so it
  /// no longer blocks the next selection or the review.
  Future<void> withdraw(MailDraft draft, {required String reason});
}
