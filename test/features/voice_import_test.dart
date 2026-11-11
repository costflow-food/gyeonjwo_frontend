import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_draft/data/mail_draft_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft_repository.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_repository_impl.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review_repository.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/recording_supplier_source.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/voice_file_picker.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/recording_supplier.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/voice_file.dart";
import "package:gyeonjwo_frontend/features/voice_import/presentation/voice_import_flow.dart";
import "package:gyeonjwo_frontend/features/voice_import/presentation/widgets/call_recording_section.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/candidate.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// Answers each pick from [results]: a file, null (cancelled) or an error.
class _Picker implements VoiceFilePicker {
  _Picker(this.results);

  final List<Object?> results;
  int picks = 0;

  @override
  Future<VoiceFile?> pick() async {
    final result = results[picks++];
    if (result is Exception) throw result;
    return result as VoiceFile?;
  }
}

VoiceFile _file(String name, int size) => VoiceFile(
  name: name,
  extension: name.split(".").last,
  sizeBytes: size,
  uri: Uri.parse("content://media/$name"),
);

const _caseTitle = "[달콤농원] 냉동 딸기 적용일 협의 안내";
const RecordingSupplierQuery _query = (caseId: "c1", responded: 1);

const _suppliers = [
  RecordingSupplier(
    supplierId: "s1",
    name: "프레시팜",
    email: "fresh@example.invalid",
    replied: true,
  ),
  RecordingSupplier(
    supplierId: "s2",
    name: "새벽딸기",
    email: "dawn@example.invalid",
    replied: false,
  ),
];

/// A case screen stand-in with the 통화 녹음 section. Without [repositories]
/// the supplier list is [_suppliers]; with them the real provider reads it.
Future<void> _pumpCase(
  WidgetTester tester,
  _Picker picker, {
  List<Object>? repositories,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceFilePickerProvider.overrideWithValue(picker),
        if (repositories == null)
          recordingSuppliersProvider(_query)
              .overrideWith((ref) async => _suppliers)
        else
          ...repositories.cast(),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CallRecordingSection(
                onAdd: () => addCallRecording(
                  context,
                  ref,
                  caseTitle: _caseTitle,
                  suppliers: _query,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester) async {
  await tester.tap(find.text("통화 녹음 추가"));
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String label) => tester
    .widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    )
    .enabled;

MailDraft _draft(
  String id,
  String supplierId, {
  DraftPurpose purpose = DraftPurpose.rfq,
  DraftStatus status = DraftStatus.sent,
}) => MailDraft(
  id: id,
  caseId: "c1",
  supplierId: supplierId,
  purpose: purpose,
  recipient: "$supplierId@example.invalid",
  subject: "견적 요청",
  body: "본문",
  status: status,
  inputRevision: 1,
  snapshotHash: "hash",
  settingsConfigured: true,
);

class _Drafts implements MailDraftRepository {
  _Drafts(this.drafts, {this.failures = 0});

  final List<MailDraft> drafts;

  /// How many reads fail before one succeeds.
  int failures;
  int reads = 0;

  @override
  Future<List<MailDraft>> getDrafts(String caseId) async {
    reads++;
    if (failures-- > 0) {
      throw const MailDraftFailure("NETWORK_UNAVAILABLE", "연결하지 못했습니다.");
    }
    return drafts;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Names implements WorkQueueRepository {
  @override
  Future<CandidateSet> getCandidates(String caseId) async => const CandidateSet(
    id: "set",
    revision: 1,
    candidates: [
      Candidate(supplierId: "s1", name: "프레시팜", handlingEvidence: ""),
      Candidate(supplierId: "s2", name: "새벽딸기", handlingEvidence: ""),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Quotes implements PurchaseReviewRepository {
  _Quotes(this.supplierIds, {this.fails = false});

  /// Suppliers with a quote; "old" is the incumbent.
  final List<String> supplierIds;
  final bool fails;

  @override
  Future<List<QuoteVersion>> getQuotes(String caseId) async {
    if (fails) throw const PurchaseReviewFailure("NOT_READY", "아직 없습니다.");
    return [
      for (final id in supplierIds)
        QuoteVersion(
          quoteId: "q-$id",
          versionNo: 1,
          supplierId: id,
          supplierName: id,
          isIncumbent: id == "old",
          extractionStatus: "DONE",
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<List<RecordingSupplier>> _load(
  List<MailDraft> drafts,
  _Quotes quotes, {
  int? responded,
}) {
  final container = ProviderContainer(
    overrides: [
      mailDraftRepositoryProvider.overrideWithValue(_Drafts(drafts)),
      workQueueRepositoryProvider.overrideWithValue(_Names()),
      purchaseReviewRepositoryProvider.overrideWithValue(quotes),
    ],
  );
  addTearDown(container.dispose);
  return container.read(
    recordingSuppliersProvider((caseId: "c1", responded: responded)).future,
  );
}

void main() {
  testWidgets("the upload needs a supplier chosen first", (tester) async {
    final picker = _Picker([
      _file("통화 녹음 새벽딸기_20261111_1432.m4a", 2516582),
      _file("회의_단가협의.mp3", 13317357),
    ]);
    await _pumpCase(tester, picker);
    await _choose(tester);
    expect(find.text("통화 녹음 추가"), findsOneWidget);
    expect(find.text(_caseTitle), findsOneWidget);
    expect(find.text("통화 녹음 새벽딸기_20261111_1432.m4a"), findsOneWidget);
    expect(find.text("M4A · 2.4MB"), findsOneWidget);
    // The requested suppliers, with what is known about their replies.
    expect(find.text("어느 거래처와의 통화입니까?"), findsOneWidget);
    expect(find.text("프레시팜"), findsOneWidget);
    expect(find.text("메일 회신 있음"), findsOneWidget);
    expect(find.text("회신 전"), findsOneWidget);
    expect(_enabled(tester, "거래처를 골라 주세요"), isFalse);

    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    expect(find.text("거래처를 골라 주세요"), findsNothing);
    // No upload API yet.
    expect(_enabled(tester, "업로드 · 준비 중"), isFalse);

    // 다른 파일 replaces the file and keeps the supplier.
    await tester.tap(find.text("다른 파일"));
    await tester.pumpAndSettle();
    expect(find.text("회의_단가협의.mp3"), findsOneWidget);
    expect(find.text("MP3 · 12.7MB"), findsOneWidget);
    expect(find.text("업로드 · 준비 중"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a failed supplier read shows its error and retries on tap", (
    tester,
  ) async {
    final drafts = _Drafts([_draft("d1", "s1")], failures: 1);
    await _pumpCase(
      tester,
      _Picker([_file("통화.m4a", 1024)]),
      repositories: [
        mailDraftRepositoryProvider.overrideWithValue(drafts),
        workQueueRepositoryProvider.overrideWithValue(_Names()),
        purchaseReviewRepositoryProvider.overrideWithValue(_Quotes([])),
      ],
    );
    await _choose(tester);
    // At once: no automatic retries hiding the error behind a spinner.
    expect(find.text("거래처 목록을 불러오지 못했습니다."), findsOneWidget);
    expect(drafts.reads, 1);
    expect(_enabled(tester, "거래처를 골라 주세요"), isFalse);

    await tester.tap(find.text("다시 시도"));
    await tester.pumpAndSettle();
    expect(drafts.reads, 2);
    expect(find.text("프레시팜"), findsOneWidget);
    expect(find.text("거래처 목록을 불러오지 못했습니다."), findsNothing);
  });

  testWidgets("a case with no sent request has nothing to choose", (
    tester,
  ) async {
    await _pumpCase(
      tester,
      _Picker([_file("통화.m4a", 1024)]),
      repositories: [
        mailDraftRepositoryProvider.overrideWithValue(
          _Drafts([_draft("d1", "s1", status: DraftStatus.draft)]),
        ),
        workQueueRepositoryProvider.overrideWithValue(_Names()),
        purchaseReviewRepositoryProvider.overrideWithValue(_Quotes([])),
      ],
    );
    await _choose(tester);
    expect(find.text("견적 요청을 보낸 거래처가 없습니다."), findsOneWidget);
    expect(_enabled(tester, "거래처를 골라 주세요"), isFalse);
  });

  testWidgets("a file that is not a recording only shows a message", (
    tester,
  ) async {
    await _pumpCase(tester, _Picker([const VoiceFileRejected()]));
    await _choose(tester);
    expect(find.text("오디오 파일만 가져올 수 있습니다."), findsOneWidget);
    expect(find.text(_caseTitle), findsNothing);
  });

  testWidgets("cancelling the picker stays on the case", (tester) async {
    final picker = _Picker([null]);
    await _pumpCase(tester, picker);
    await _choose(tester);
    expect(picker.picks, 1);
    expect(find.text("통화 녹음"), findsOneWidget);
    expect(find.text(_caseTitle), findsNothing);
  });

  test("the 통화 녹음 section follows the queue's reply summary", () {
    WorkCase workCase(ReplySummary? replies) => WorkCase(
      id: "c1",
      initialMailId: "m1",
      title: "제목",
      sender: "a@example.invalid",
      receivedAt: "2026-11-10T00:00:00Z",
      status: WorkCaseStatus.fromCode("Running"),
      statusCode: "Running",
      processingStep: "WAITING_REPLY",
      stepMessage: "",
      inputRevision: 1,
      attachmentCount: 0,
      replySummary: replies,
    );
    // No request went out: no section.
    expect(
      recordingSupplierQueryOf(
        workCase(const ReplySummary(requested: 0, responded: 0)),
      ),
      isNull,
    );
    // Requests out: the reply count checks the per-supplier marks.
    expect(
      recordingSupplierQueryOf(
        workCase(const ReplySummary(requested: 3, responded: 1)),
      ),
      (caseId: "c1", responded: 1),
    );
    // Read on its own (API-02) the case has no summary: ask the suppliers.
    expect(recordingSupplierQueryOf(workCase(null)), (
      caseId: "c1",
      responded: null,
    ));
  });

  group("suppliers a recording can belong to", () {
    test("only those whose 견적 요청 was sent, once each", () async {
      final suppliers = await _load(
        [
          _draft("d1", "s1"),
          _draft("d2", "s1"),
          _draft("d3", "s2", status: DraftStatus.draft),
          _draft("d4", "s3", status: DraftStatus.failed),
          _draft("d5", "old", purpose: DraftPurpose.counterOffer),
        ],
        _Quotes([]),
        responded: 0,
      );
      expect([for (final s in suppliers) s.supplierId], ["s1"]);
      expect(suppliers.single.name, "프레시팜");
      expect(suppliers.single.email, "s1@example.invalid");
    });

    test("reply marks show when they agree with the case's count", () async {
      final suppliers = await _load(
        [_draft("d1", "s1"), _draft("d2", "s2")],
        // The incumbent's own quote is not a reply to a request.
        _Quotes(["s1", "old"]),
        responded: 1,
      );
      expect(
        {for (final s in suppliers) s.supplierId: s.replied},
        {"s1": true, "s2": false},
      );
    });

    test("no reply marks when the count disagrees or quotes fail", () async {
      final drafts = [_draft("d1", "s1"), _draft("d2", "s2")];
      final disagree = await _load(drafts, _Quotes(["s1"]), responded: 2);
      expect([for (final s in disagree) s.replied], [null, null]);
      final failed = await _load(
        drafts,
        _Quotes([], fails: true),
        responded: 1,
      );
      expect([for (final s in failed) s.replied], [null, null]);
      // Without a registered name the address stands in.
      expect(
        (await _load(
          [_draft("d9", "s9")],
          _Quotes([]),
          responded: 0,
        )).single.name,
        "s9@example.invalid",
      );
    });
  });
}
