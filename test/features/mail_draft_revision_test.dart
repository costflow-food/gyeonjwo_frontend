import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_draft/data/mail_draft_data_source.dart";
import "package:gyeonjwo_frontend/features/mail_draft/data/mail_draft_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/mail_draft_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";

Map<String, dynamic> _json(String id, String status, {String? sendState}) => {
  "draft_id": id,
  "case_id": "case-1",
  "supplier_id": "supplier-1",
  "purpose": "RFQ",
  "recipient": "supplier@example.invalid",
  "subject": "견적 요청",
  "body_text": "본문",
  "status": status,
  "input_revision": 1,
  "snapshot_hash": "hash-$id",
  "effective_send_policy": {
    "configured": true,
    "approval_required": true,
    "settings_version": "v1",
  },
  if (sendState != null) "send_state": {"code": sendState},
};

/// API-16·17·18 over an in-memory list. A revision adds a DRAFT and answers
/// with IDs only, as the server does.
class _FakeDrafts implements MailDraftDataSource {
  _FakeDrafts(this.rows);

  final List<Map<String, dynamic>> rows;
  final revisionBodies = <Map<String, Object?>>[];
  Map<String, dynamic>? revisionData;

  @override
  Future<Map<String, dynamic>> fetchDrafts(
    String caseId, {
    String? cursor,
  }) async => {
    "data": {"items": rows, "next_cursor": null},
  };

  @override
  Future<Map<String, dynamic>> fetchDraft(String draftId) async => {
    "data": rows.firstWhere((row) => row["draft_id"] == draftId),
  };

  @override
  Future<Map<String, dynamic>> createRevision(
    String draftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    revisionBodies.add(body);
    rows.insert(0, _json("draft-2", "DRAFT"));
    return {
      "data":
          revisionData ??
          {
            "case_id": "case-1",
            "draft_id": "draft-2",
            "replaces_id": draftId,
            "input_revision": 1,
          },
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Supplier names are optional; the view model falls back to the address.
class _NoQueue implements WorkQueueRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _input = DraftRevisionInput(
  recipient: "supplier@example.invalid",
  subject: "견적 요청 (수정)",
  body: "고친 본문",
  editReason: "수신자 확인 후 재발송",
);

void main() {
  test("a withdrawn draft reads as 보내지 않음, not as a failed send", () async {
    final repository = MailDraftRepositoryImpl(
      _FakeDrafts([
        _json("withdrawn", "FAILED", sendState: "DRAFT_WITHDRAWN"),
        _json("failed", "FAILED", sendState: "SEND_FAILED"),
      ]),
    );
    final drafts = await repository.getDrafts("case-1");

    expect(drafts[0].status, DraftStatus.withdrawn);
    expect(drafts[0].status.label, "보내지 않음");
    expect(drafts[0].can(DraftAction.edit), isFalse);
    expect(drafts[0].can(DraftAction.withdraw), isFalse);
    expect(drafts[1].status, DraftStatus.failed);
  });

  test("a failed draft can be revised, a stale one cannot", () async {
    final repository = MailDraftRepositoryImpl(
      _FakeDrafts([
        _json("failed", "FAILED"),
        {..._json("stale", "DRAFT"), "is_stale": true},
      ]),
    );
    final drafts = await repository.getDrafts("case-1");

    expect(drafts[0].can(DraftAction.edit), isTrue);
    expect(drafts[1].can(DraftAction.edit), isFalse);
  });

  test(
    "a revision sends its reason and opens the new draft after a re-read",
    () async {
      final source = _FakeDrafts([_json("draft-1", "FAILED")]);
      final container = ProviderContainer(
        overrides: [
          mailDraftRepositoryProvider.overrideWithValue(
            MailDraftRepositoryImpl(source),
          ),
          workQueueRepositoryProvider.overrideWithValue(_NoQueue()),
        ],
      );
      addTearDown(container.dispose);
      final provider = mailDraftViewModelProvider("case-1");
      container.listen(provider, (previous, next) {});
      final failed = (await container.read(provider.future)).single;

      final revised = await container
          .read(provider.notifier)
          .revise(failed, _input);

      expect(source.revisionBodies.single["edit_reason"], "수신자 확인 후 재발송");
      expect(revised.id, "draft-2");
      expect(revised.status, DraftStatus.draft);
      expect(container.read(provider).requireValue.map((draft) => draft.id), [
        "draft-2",
        "draft-1",
      ]);
    },
  );

  test(
    "a revision answer that is not the new draft's IDs is rejected",
    () async {
      final source = _FakeDrafts([_json("draft-1", "FAILED")])
        ..revisionData = _json("draft-1", "DRAFT");
      final repository = MailDraftRepositoryImpl(source);
      final failed = (await repository.getDrafts("case-1")).single;

      await expectLater(
        repository.createRevision(failed, _input),
        throwsA(
          isA<MailDraftFailure>().having(
            (failure) => failure.code,
            "code",
            "INVALID_RESPONSE",
          ),
        ),
      );
    },
  );
}
