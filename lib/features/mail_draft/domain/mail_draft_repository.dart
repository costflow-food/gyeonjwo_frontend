import "mail_draft.dart";

/// Retries of the same action and body reuse one idempotency key.
abstract interface class MailDraftRepository {
  /// API-16. Latest draft per purpose and supplier for one case.
  Future<List<MailDraft>> getDrafts(String caseId);

  /// API-18. Returns the new draft that replaces [draft].
  Future<MailDraft> createRevision(MailDraft draft, DraftRevisionInput input);

  /// API-19. Approval ON only; the result is SENDING until Gmail confirms.
  Future<MailDraft> approveAndSend(MailDraft draft);

  /// API-20. Checks the sent folder. Never re-sends.
  Future<MailDraft> reconcile(MailDraft draft);
}
