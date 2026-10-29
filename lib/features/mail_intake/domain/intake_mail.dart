/// Temporary app models for SCR-009; independent of the mail_messages schema.
library;

/// Only mails the classifier could not settle reach this screen.
enum IntakeReason {
  uncertain("UNCERTAIN", "업무 여부 판단 불가"),
  ambiguous("AMBIGUOUS", "연결할 업무가 여럿");

  const IntakeReason(this.code, this.label);
  final String code;
  final String label;

  static IntakeReason fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => IntakeReason.uncertain,
  );
}

enum IntakeResolution {
  nonBusiness("NON_BUSINESS"),
  createCase("CREATE_CASE"),
  linkCase("LINK_CASE");

  const IntakeResolution(this.code);
  final String code;
}

/// An existing case the mail might belong to, with what differs.
class CaseCandidate {
  const CaseCandidate({
    required this.caseId,
    required this.title,
    required this.status,
    this.itemName,
    this.conditions,
    this.difference,
    this.replyEvidence,
  });

  final String caseId;
  final String title;
  final String status;
  final String? itemName;
  final String? conditions;
  final String? difference;

  /// Reply headers or an earlier send that point to this case.
  final String? replyEvidence;
}

class IntakeMail {
  const IntakeMail({
    required this.mailId,
    required this.subject,
    required this.sender,
    required this.receivedAt,
    required this.bodyText,
    required this.reason,
    required this.reasonDetail,
    required this.attachments,
    required this.candidates,
    required this.revision,
  });

  final String mailId;
  final String subject;
  final String sender;

  /// UTC ISO 8601.
  final String receivedAt;
  final String bodyText;
  final IntakeReason reason;

  /// Classifier's short reason. Not a model reasoning trace.
  final String reasonDetail;
  final List<String> attachments;
  final List<CaseCandidate> candidates;
  final int revision;
}

class IntakePage {
  const IntakePage({
    required this.items,
    required this.totalPending,
    this.nextCursor,
  });

  final List<IntakeMail> items;

  /// Same count as API-01 intake_pending.
  final int totalPending;
  final String? nextCursor;
}

class IntakeFailure implements Exception {
  const IntakeFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => "IntakeFailure($code)";
}
