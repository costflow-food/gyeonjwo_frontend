import "intake_mail.dart";

abstract interface class MailIntakeRepository {
  /// API-23. Unresolved UNCERTAIN/AMBIGUOUS mails, newest first.
  Future<IntakePage> getPending({String? cursor});

  /// API-24. Creating a case leaves it Waiting; it never starts a review.
  Future<void> resolve(
    IntakeMail mail,
    IntakeResolution resolution, {
    String? targetCaseId,
    String? reason,
    required String idempotencyKey,
  });
}
