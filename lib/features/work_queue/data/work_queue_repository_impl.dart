import "dart:typed_data";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/idempotency_key.dart";

import "../domain/candidate.dart";
import "../domain/work_case.dart";
import "../domain/work_queue_repository.dart";
import "work_queue_data_source.dart";

part "work_queue_repository_impl.g.dart";

@Riverpod(keepAlive: true)
WorkQueueRepository workQueueRepository(Ref ref) {
  return WorkQueueRepositoryImpl(ref.watch(workQueueDataSourceProvider));
}

class WorkQueueRepositoryImpl implements WorkQueueRepository {
  WorkQueueRepositoryImpl(this._dataSource);

  final WorkQueueDataSource _dataSource;
  final _keys = IdempotencyKeys();

  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
  }) => _guard(() async {
    final response = await _dataSource.fetchCases(
      status: status == null || status == WorkCaseStatus.other
          ? null
          : status.code,
      query: query,
      cursor: cursor,
    );
    final data = response["data"] as Map<String, dynamic>;
    final counts = data["counts"] as Map<String, dynamic>;
    return WorkQueuePage(
      items: List.unmodifiable([
        for (final entry in data["items"] as List)
          _case(entry as Map<String, dynamic>),
      ]),
      counts: WorkQueueCounts(
        waiting: counts["Waiting"] as int? ?? 0,
        running: counts["Running"] as int? ?? 0,
        complete: counts["Complete"] as int? ?? 0,
        total: counts["total"] as int? ?? 0,
      ),
      nextCursor: data["next_cursor"] as String?,
    );
  });

  @override
  Future<OriginalMail> getOriginalMail(String mailId) => _guard(() async {
    final response = await _dataSource.fetchOriginalMail(mailId);
    final json = response["data"] as Map<String, dynamic>;
    return OriginalMail(
      id: json["mail_id"] as String,
      subject: json["subject"] as String,
      sender: json["sender"] as String,
      recipients: List.unmodifiable(
        (json["recipients"] as List).cast<String>(),
      ),
      receivedAt: json["received_at"] as String,
      bodyText: json["body_text"] as String,
      attachments: List.unmodifiable([
        for (final entry in json["attachments"] as List)
          MailAttachment(
            id: entry["attachment_id"] as String,
            filename: entry["filename"] as String,
            mimeType: entry["mime_type"] as String,
            sizeBytes: entry["size_bytes"] as int,
          ),
      ]),
    );
  });

  @override
  Future<Uint8List> getAttachmentContent(String mailId, String attachmentId) =>
      _guard(() => _dataSource.fetchAttachmentContent(mailId, attachmentId));

  @override
  Future<void> acceptIncrease(WorkCase workCase) {
    final body = <String, Object?>{"expected_revision": workCase.inputRevision};
    return _keys.run(
      "accept:${workCase.id}",
      body,
      (key) => _guard(
        () =>
            _dataSource.acceptIncrease(workCase.id, body, idempotencyKey: key),
      ),
      serverCode: _serverCode,
    );
  }

  @override
  Future<void> start(WorkCase workCase) {
    final body = <String, Object?>{"expected_revision": workCase.inputRevision};
    return _keys.run(
      "start:${workCase.id}",
      body,
      (key) => _guard(
        () => _dataSource.start(workCase.id, body, idempotencyKey: key),
      ),
      serverCode: _serverCode,
    );
  }

  @override
  Future<CaseProgress> getProgress(String caseId) => _guard(() async {
    final response = await _dataSource.fetchProgress(caseId);
    final json = response["data"] as Map<String, dynamic>;
    final error = json["error"] as Map<String, dynamic>?;
    return CaseProgress(
      caseId: json["case_id"] as String,
      status: json["status"] as String,
      processingStep: json["processing_step"] as String,
      inputRevision: json["input_revision"] as int,
      hold: _hold(json["hold"]),
      errorCode: error?["code"] as String?,
    );
  });

  @override
  Future<void> resume(WorkCase workCase) {
    // This release accepts only RESUME_HOLD; the server rejects other reasons.
    final body = <String, Object?>{
      "expected_revision": workCase.inputRevision,
      "reason": "RESUME_HOLD",
    };
    return _keys.run(
      "resume:${workCase.id}",
      body,
      (key) => _guard(
        () => _dataSource.resume(workCase.id, body, idempotencyKey: key),
      ),
      serverCode: _serverCode,
    );
  }

  @override
  Future<CandidateSet> getCandidates(String caseId) => _guard(() async {
    final response = await _dataSource.fetchCandidates(caseId);
    final json = response["data"] as Map<String, dynamic>;
    return CandidateSet(
      id: json["candidate_set_id"] as String,
      revision: json["revision"] as int,
      selectedSupplierIds: List.unmodifiable(
        (json["selected_supplier_ids"] as List? ?? const []).cast<String>(),
      ),
      candidates: List.unmodifiable([
        for (final entry in json["items"] as List)
          Candidate(
            supplierId: entry["supplier_id"] as String,
            name: entry["name"] as String,
            contactEmail: entry["contact_email"] as String?,
            handlingEvidence: entry["handling_evidence"] as String? ?? "",
            preferenceScore: entry["preference_score"] as int?,
            webCandidate: entry["is_web_candidate"] as bool? ?? false,
            checks: List.unmodifiable([
              for (final check in entry["checks"] as List? ?? const [])
                CandidateCheck(
                  label: check["label"] as String,
                  state: CheckState.fromCode(check["status"] as String),
                  required: check["required"] as bool? ?? true,
                ),
            ]),
          ),
      ]),
    );
  });

  @override
  Future<void> selectCandidates(
    WorkCase workCase,
    CandidateSet candidates,
    List<String> supplierIds,
  ) {
    final body = <String, Object?>{
      "expected_revision": workCase.inputRevision,
      "candidate_set_id": candidates.id,
      "selected_supplier_ids": [...supplierIds]..sort(),
    };
    return _keys.run(
      "select:${workCase.id}",
      body,
      (key) => _guard(
        () => _dataSource.selectCandidates(
          workCase.id,
          body,
          idempotencyKey: key,
        ),
      ),
      serverCode: _serverCode,
    );
  }

  /// A lost response keeps the key so a retry only checks the first request.
  static String? _serverCode(Object error) =>
      error is WorkQueueFailure && !error.unknownOutcome ? error.code : null;

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on WorkQueueApiException catch (error) {
      throw WorkQueueFailure(
        error.code,
        error.message,
        unknownOutcome: error.unknownOutcome,
      );
    }
  }

  static HoldReason? _hold(Object? json) => json is Map<String, dynamic>
      ? HoldReason(
          code: json["code"] as String,
          message: json["message"] as String,
        )
      : null;

  static WorkCase _case(Map<String, dynamic> json) {
    final statusCode = json["status"] as String;
    final step = json["step_detail"] as Map<String, dynamic>?;
    return WorkCase(
      id: json["case_id"] as String,
      initialMailId: json["initial_mail_id"] as String,
      title: json["title"] as String,
      sender: json["sender"] as String,
      senderName: json["sender_name"] as String?,
      itemName: json["item_name"] as String?,
      receivedAt: json["received_at"] as String,
      status: WorkCaseStatus.fromCode(statusCode),
      statusCode: statusCode,
      processingStep: json["processing_step"] as String,
      stepMessage: step?["message"] as String? ?? "",
      inputRevision: json["input_revision"] as int,
      attachmentCount: json["attachment_count"] as int? ?? 0,
      hold: _hold(json["hold"]),
      allowedActions: List.unmodifiable(
        (json["allowed_actions"] as List? ?? const []).cast<String>(),
      ),
      disabledActions: List.unmodifiable([
        for (final entry in json["disabled_actions"] as List? ?? const [])
          DisabledWorkCaseAction(
            action: entry["action"] as String,
            reasonCode: entry["reason_code"] as String,
            message: entry["message"] as String,
          ),
      ]),
    );
  }
}
