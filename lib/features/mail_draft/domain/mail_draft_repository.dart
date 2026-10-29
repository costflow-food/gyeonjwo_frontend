import "mail_draft.dart";

abstract interface class MailDraftRepository {
  /// API-16. Latest draft per purpose and supplier for one case.
  Future<List<MailDraft>> getDrafts(String caseId);

  /// API-18. Returns the new draft that replaces [draft].
  Future<MailDraft> createRevision(
    MailDraft draft,
    DraftRevisionInput input, {
    required String idempotencyKey,
  });

  /// API-19. Approval ON only; the result is SENDING until Gmail confirms.
  Future<MailDraft> approveAndSend(
    MailDraft draft, {
    required String idempotencyKey,
  });

  /// API-20. Checks the sent folder. Never re-sends.
  Future<MailDraft> reconcile(
    MailDraft draft, {
    required String idempotencyKey,
  });
}
