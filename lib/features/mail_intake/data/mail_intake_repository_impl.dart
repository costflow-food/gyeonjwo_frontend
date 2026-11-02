import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/idempotency_key.dart";

import "../domain/intake_mail.dart";
import "../domain/mail_intake_repository.dart";
import "mail_intake_data_source.dart";

part "mail_intake_repository_impl.g.dart";

@Riverpod(keepAlive: true)
MailIntakeRepository mailIntakeRepository(Ref ref) {
  return MailIntakeRepositoryImpl(ref.watch(mailIntakeDataSourceProvider));
}

class MailIntakeRepositoryImpl implements MailIntakeRepository {
  MailIntakeRepositoryImpl(this._dataSource);

  final MailIntakeDataSource _dataSource;
  final _keys = IdempotencyKeys();

  @override
  Future<IntakePage> getPending({String? cursor}) => _guard(() async {
    final response = await _dataSource.fetchPending(cursor: cursor);
    final data = response["data"] as Map<String, dynamic>;
    return IntakePage(
      items: List.unmodifiable([
        for (final entry in data["items"] as List)
          _mail(entry as Map<String, dynamic>),
      ]),
      totalPending: data["total_pending"] as int,
      nextCursor: data["next_cursor"] as String?,
    );
  });

  @override
  Future<void> resolve(
    IntakeMail mail,
    IntakeResolution resolution, {
    String? targetCaseId,
    String? reason,
  }) {
    final body = <String, Object?>{
      "resolution": resolution.code,
      "target_case_id": targetCaseId,
      "expected_revision": mail.revision,
      "reason": reason,
    };
    return _keys.run(
      "resolve:${mail.mailId}",
      body,
      (key) => _guard(
        () => _dataSource.resolve(mail.mailId, body, idempotencyKey: key),
      ),
      serverCode: (error) => error is IntakeFailure ? error.code : null,
    );
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on MailIntakeApiException catch (error) {
      throw IntakeFailure(error.code, error.message);
    }
  }

  static IntakeMail _mail(Map<String, dynamic> json) => IntakeMail(
    mailId: json["mail_id"] as String,
    subject: json["subject"] as String,
    sender: json["sender"] as String,
    receivedAt: json["received_at"] as String,
    bodyText: json["body_text"] as String,
    reason: IntakeReason.fromCode(json["mail_classification"] as String),
    reasonDetail: json["reason_detail"] as String,
    attachments: List.unmodifiable(
      (json["attachments"] as List).cast<String>(),
    ),
    revision: json["revision"] as int,
    candidates: List.unmodifiable([
      for (final entry in json["candidates"] as List)
        CaseCandidate(
          caseId: entry["case_id"] as String,
          title: entry["title"] as String,
          status: entry["status"] as String,
          itemName: entry["item_name"] as String?,
          conditions: entry["conditions"] as String?,
          difference: entry["difference"] as String?,
          replyEvidence: entry["reply_evidence"] as String?,
        ),
    ]),
  );
}
