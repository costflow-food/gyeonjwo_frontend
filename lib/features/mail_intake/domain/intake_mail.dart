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

  /// 기존 업무에 대한 회신으로 보이는 메일. API-23에는 답장 헤더가 없어
  /// 제목 접두어와 후보의 답장·발송 근거로 추정합니다.
  bool get looksLikeReply =>
      _replySubject.hasMatch(subject) ||
      candidates.any((candidate) => candidate.replyEvidence != null);
}

/// "RE:", "Re :", "회신:", "답장:" 같은 답장 제목 접두어.
final _replySubject = RegExp(
  r"^\s*(re|회신|답장)\s*[:：]",
  caseSensitive: false,
);

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
  const IntakeFailure(
    this.code,
    this.message, {
    this.unknownOutcome = false,
    this.retryable = false,
  });
  final String code;
  final String message;

  /// No response arrived; the server may or may not have applied the change.
  final bool unknownOutcome;

  /// 응답 없음·5xx·`retryable: true`: 서버가 처리했을 수 있어 같은 멱등 키를
  /// 남기고 상태를 다시 읽습니다. [unknownOutcome]이면 늘 참입니다.
  final bool retryable;

  @override
  String toString() => "IntakeFailure($code)";
}
