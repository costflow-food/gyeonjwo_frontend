import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_draft/data/mail_draft_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft_repository.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_repository_impl.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review_repository.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/call_recording_repository_impl.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/recording_supplier_source.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/voice_file_picker.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/call_recording.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/call_recording_repository.dart";
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
    if (result is Future<VoiceFile?>) return result;
    return result as VoiceFile?;
  }
}

VoiceFile _file(String name, int size) => VoiceFile(
  name: name,
  extension: name.split(".").last,
  sizeBytes: size,
  uri: Uri.parse("file:///cache/file_picker/$name"),
  openRead: () => Stream.value(const [1, 2, 3]),
);

CallRecording _recording(
  String id, {
  String supplierId = "s2",
  CallRecordingStatus status = CallRecordingStatus.uploaded,
}) => CallRecording(
  recordingId: id,
  supplierId: supplierId,
  fileName: "통화 녹음 새벽딸기_20261111_1432.m4a",
  extension: "m4a",
  sizeBytes: 2516582,
  status: status,
  createdAt: "2026-11-11T05:40:00Z",
  uploadedAt: status == CallRecordingStatus.uploaded
      ? "2026-11-11T05:41:00Z"
      : null,
);

/// The server's side of the recordings: what the list shows, and how each
/// upload ends. An upload with no scripted end waits for [finish].
class _Recordings implements CallRecordingRepository {
  _Recordings({
    this.unavailable = false,
    this.maxPerCase = 10,
    this.deletable = true,
  });

  /// A server that does not have the feature yet.
  final bool unavailable;
  final int maxPerCase;

  /// Whether the server offers deleting.
  final bool deletable;
  final items = <CallRecording>[];

  /// Recordings asked to be deleted, in order; those in [undeletable] fail.
  final deletes = <String>[];
  final undeletable = <String>{};

  /// Deleted on the server, but the answer never arrives.
  final lostAnswers = <String>{};

  /// Set to hold the next delete until completed.
  Completer<void>? deleting;
  final uploads = <({String caseId, String supplierId, VoiceFile file})>[];

  /// Failures for the next uploads, in order; after them uploads wait.
  final failures = <CallRecordingFailure>[];
  Completer<void>? finish;
  void Function(RecordingUploadStep step)? onStep;
  void Function(int sent, int total)? onProgress;

  @override
  Future<CallRecordingList> getRecordings(String caseId) async {
    if (unavailable) {
      throw const CallRecordingFailure(
        "CALL_RECORDING_UNAVAILABLE",
        "통화 녹음 기능을 사용할 수 없습니다.",
      );
    }
    return CallRecordingList(
      items: [...items],
      maxPerCase: maxPerCase,
      maxBytes: defaultMaxRecordingBytes,
      deletable: deletable,
    );
  }

  @override
  Future<void> deleteRecording(String caseId, String recordingId) async {
    deletes.add(recordingId);
    await deleting?.future;
    if (lostAnswers.contains(recordingId)) {
      items.removeWhere((item) => item.recordingId == recordingId);
      throw const CallRecordingFailure(
        "NETWORK_ERROR",
        "서버 응답을 받지 못했습니다.",
        unknownOutcome: true,
      );
    }
    if (undeletable.contains(recordingId)) {
      throw const CallRecordingFailure(
        "CALL_RECORDING_DELETE_NOT_ALLOWED",
        "지금은 이 녹음을 삭제할 수 없습니다.",
      );
    }
    items.removeWhere((item) => item.recordingId == recordingId);
  }

  @override
  Future<CallRecording> upload({
    required String caseId,
    required String supplierId,
    required VoiceFile file,
    void Function(RecordingUploadStep step)? onStep,
    void Function(int sent, int total)? onProgress,
  }) async {
    uploads.add((caseId: caseId, supplierId: supplierId, file: file));
    if (unavailable) {
      throw const CallRecordingFailure(
        "CALL_RECORDING_UNAVAILABLE",
        "통화 녹음 기능을 사용할 수 없습니다.",
      );
    }
    this.onStep = onStep;
    this.onProgress = onProgress;
    onStep?.call(RecordingUploadStep.requesting);
    if (failures.isNotEmpty) {
      // Like the server: the slot is taken and the row stays unfinished.
      if (items.every((item) => item.recordingId != "pending")) {
        items.insert(
          0,
          _recording(
            "pending",
            supplierId: supplierId,
            status: CallRecordingStatus.uploading,
          ),
        );
      }
      throw failures.removeAt(0);
    }
    await (finish = Completer<void>()).future;
    items.removeWhere((item) => item.recordingId == "pending");
    final recording = _recording("r${uploads.length}", supplierId: supplierId);
    items.insert(0, recording);
    return recording;
  }
}

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
  _Recordings? recordings,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceFilePickerProvider.overrideWithValue(picker),
        callRecordingRepositoryProvider.overrideWithValue(
          recordings ?? _Recordings(),
        ),
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
                suppliers: _query,
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
    expect(_enabled(tester, "업로드"), isTrue);

    // 다른 파일 replaces the file and keeps the supplier.
    await tester.tap(find.text("다른 파일"));
    await tester.pumpAndSettle();
    expect(find.text("회의_단가협의.mp3"), findsOneWidget);
    expect(find.text("MP3 · 12.7MB"), findsOneWidget);
    expect(_enabled(tester, "업로드"), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a server without call recordings answers the upload itself", (
    tester,
  ) async {
    final recordings = _Recordings(unavailable: true);
    await _pumpCase(
      tester,
      _Picker([_file("통화.m4a", 1024)]),
      recordings: recordings,
    );
    // The section still offers the add tile; there is just no list.
    expect(find.text("통화 녹음"), findsOneWidget);
    expect(find.text("올린 녹음을 불러오지 못했습니다."), findsNothing);
    await _choose(tester);
    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    // No notice made up by the app: the upload is offered as usual and the
    // server's own answer is shown.
    expect(find.textContaining("준비"), findsNothing);
    expect(_enabled(tester, "업로드"), isTrue);
    await tester.tap(find.text("업로드"));
    await tester.pumpAndSettle();
    expect(recordings.uploads, hasLength(1));
    expect(find.text("통화 녹음 기능을 사용할 수 없습니다."), findsOneWidget);
    expect(_enabled(tester, "다시 시도"), isTrue);
  });

  testWidgets("an upload shows its progress, then lists the recording", (
    tester,
  ) async {
    final recordings = _Recordings();
    final file = _file("통화 녹음 새벽딸기_20261111_1432.m4a", 2516582);
    await _pumpCase(tester, _Picker([file]), recordings: recordings);
    await _choose(tester);
    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("업로드"));
    await tester.pump();

    expect(recordings.uploads.single, (
      caseId: "c1",
      supplierId: "s2",
      file: file,
    ));
    expect(_enabled(tester, "업로드 준비 중"), isFalse);
    expect(_enabled(tester, "다른 파일"), isFalse);
    recordings.onStep!(RecordingUploadStep.uploading);
    recordings.onProgress!(42, 100);
    await tester.pump();
    expect(find.text("올리는 중 42%"), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.42,
    );
    // The page stays while the upload runs: a second press or back does nothing.
    await tester.tap(find.byTooltip("닫기"));
    await tester.pump();
    expect(find.text("어느 거래처와의 통화입니까?"), findsOneWidget);
    recordings.onStep!(RecordingUploadStep.confirming);
    await tester.pump();
    expect(find.text("확인 중"), findsOneWidget);

    recordings.finish!.complete();
    await tester.pumpAndSettle();
    expect(recordings.uploads, hasLength(1));
    expect(find.text("통화 녹음을 올렸습니다."), findsOneWidget);
    // Back on the case: the section lists it with its supplier and state.
    expect(find.text("어느 거래처와의 통화입니까?"), findsNothing);
    expect(find.text("통화 녹음 1"), findsOneWidget);
    expect(find.text("새벽딸기"), findsOneWidget);
    expect(find.text("업로드됨"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a failed upload says why and the same button tries again", (
    tester,
  ) async {
    final recordings = _Recordings()
      ..failures.addAll(const [
        CallRecordingFailure(
          "UPLOAD_INTERRUPTED",
          "파일을 올리는 중 연결이 끊겼습니다. 다시 시도해 주세요.",
          retryable: true,
        ),
        CallRecordingFailure(
          "NETWORK_UNAVAILABLE",
          "서버에 연결하지 못했습니다.",
          retryable: true,
          unknownOutcome: true,
        ),
      ]);
    await _pumpCase(
      tester,
      _Picker([_file("통화.m4a", 1024)]),
      recordings: recordings,
    );
    await _choose(tester);
    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("업로드"));
    await tester.pumpAndSettle();
    expect(find.text("파일을 올리는 중 연결이 끊겼습니다. 다시 시도해 주세요."), findsOneWidget);
    expect(_enabled(tester, "다시 시도"), isTrue);
    expect(_enabled(tester, "다른 파일"), isTrue);

    // Not known whether it went through: said so, without the server's words.
    await tester.tap(find.text("다시 시도"));
    await tester.pumpAndSettle();
    expect(find.text("결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."), findsOneWidget);
    expect(find.text("서버에 연결하지 못했습니다."), findsNothing);

    await tester.tap(find.text("다시 시도"));
    await tester.pump();
    recordings.finish!.complete();
    await tester.pumpAndSettle();
    expect(recordings.uploads, hasLength(3));
    expect(find.text("통화 녹음을 올렸습니다."), findsOneWidget);
  });

  testWidgets("the last free slot can still be retried", (tester) async {
    final recordings = _Recordings(maxPerCase: 1)
      ..failures.add(
        const CallRecordingFailure(
          "UPLOAD_INTERRUPTED",
          "파일을 올리는 중 연결이 끊겼습니다. 다시 시도해 주세요.",
          retryable: true,
        ),
      );
    await _pumpCase(
      tester,
      _Picker([_file("통화.m4a", 1024), _file("다른 통화.m4a", 2048)]),
      recordings: recordings,
    );
    await _choose(tester);
    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("업로드"));
    await tester.pumpAndSettle();
    // The unfinished recording now fills the case, but it is this one.
    expect(recordings.items.single.status, CallRecordingStatus.uploading);
    expect(find.textContaining("1개까지"), findsNothing);
    expect(_enabled(tester, "다시 시도"), isTrue);

    // Another file would be a new recording: the limit applies again.
    await tester.tap(find.text("다른 파일"));
    await tester.pumpAndSettle();
    expect(find.text("업무 하나에 녹음은 1개까지 올릴 수 있습니다."), findsOneWidget);
    expect(_enabled(tester, "업로드"), isFalse);
    expect(recordings.uploads, hasLength(1));
  });

  testWidgets("nothing starts while another file is still being picked", (
    tester,
  ) async {
    final picking = Completer<VoiceFile?>();
    final recordings = _Recordings();
    await _pumpCase(
      tester,
      _Picker([_file("통화.m4a", 1024), picking.future]),
      recordings: recordings,
    );
    await _choose(tester);
    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("다른 파일"));
    await tester.pump();
    expect(_enabled(tester, "다른 파일"), isFalse);
    expect(_enabled(tester, "업로드"), isFalse);
    picking.complete(_file("다른 통화.m4a", 2048));
    await tester.pumpAndSettle();
    expect(find.text("다른 통화.m4a"), findsOneWidget);
    expect(_enabled(tester, "업로드"), isTrue);
    expect(recordings.uploads, isEmpty);
  });

  testWidgets("a full case and an oversized file cannot be uploaded", (
    tester,
  ) async {
    final recordings = _Recordings(maxPerCase: 1);
    final picker = _Picker([_file("큰 녹음.wav", defaultMaxRecordingBytes + 1)]);
    await _pumpCase(tester, picker, recordings: recordings);
    await _choose(tester);
    await tester.tap(find.text("새벽딸기"));
    await tester.pumpAndSettle();
    expect(find.text("녹음 파일은 50MB까지 올릴 수 있습니다."), findsOneWidget);
    expect(_enabled(tester, "업로드"), isFalse);

    // With the case at its limit the add tile itself closes.
    recordings.items.add(_recording("r1"));
    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CallRecordingSection)),
    );
    container.invalidate(callRecordingsProvider("c1"));
    await tester.pumpAndSettle();
    expect(find.text("업무 하나에 녹음은 1개까지 올릴 수 있습니다."), findsOneWidget);
    await tester.tap(find.text("통화 녹음 추가"));
    await tester.pumpAndSettle();
    expect(picker.picks, 1);
    // A failed recording does not count toward the limit.
    recordings.items
      ..clear()
      ..add(_recording("r2", status: CallRecordingStatus.failed));
    container.invalidate(callRecordingsProvider("c1"));
    await tester.pumpAndSettle();
    expect(find.text("견적을 요청한 거래처와의 통화 녹음을 붙입니다."), findsOneWidget);
  });

  group("deleting recordings", () {
    _Recordings three({bool deletable = true}) =>
        _Recordings(deletable: deletable)
          ..items.addAll([
            _recording("r1"),
            _recording(
              "r2",
              supplierId: "s1",
              status: CallRecordingStatus.uploading,
            ),
            _recording("r3", status: CallRecordingStatus.failed),
          ]);
    Finder confirm() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, "삭제"),
    );

    testWidgets("the icon shows only when there is something to delete", (
      tester,
    ) async {
      await _pumpCase(tester, _Picker([]), recordings: _Recordings());
      expect(find.byTooltip("녹음 삭제"), findsNothing);
      // A server that cannot delete yet.
      await _pumpCase(tester, _Picker([]), recordings: three(deletable: false));
      expect(find.text("통화 녹음 3"), findsOneWidget);
      expect(find.byTooltip("녹음 삭제"), findsNothing);
      await _pumpCase(tester, _Picker([]), recordings: three());
      expect(find.byTooltip("녹음 삭제"), findsOneWidget);
      // At the right end of the title row.
      expect(
        tester.getCenter(find.byTooltip("녹음 삭제")).dx,
        greaterThan(tester.getRect(find.text("통화 녹음 3")).right),
      );
      expect(
        tester.getRect(find.byTooltip("녹음 삭제")).right,
        closeTo(360 - 16, 2),
      );
    });

    testWidgets("chosen recordings are deleted together after a confirm", (
      tester,
    ) async {
      final recordings = three();
      final picker = _Picker([_file("통화.m4a", 1000)]);
      await _pumpCase(tester, picker, recordings: recordings);
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      expect(find.text("삭제할 녹음 선택"), findsOneWidget);
      expect(_enabled(tester, "삭제"), isFalse);
      // Adding is closed while choosing.
      await _choose(tester);
      expect(picker.picks, 0);
      expect(find.text("어느 거래처와의 통화입니까?"), findsNothing);

      // Unfinished and failed recordings can be chosen like any other.
      await tester.tap(find.text("프레시팜"));
      await tester.tap(find.text("실패"));
      await tester.pumpAndSettle();
      expect(find.text("2개 선택"), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsNWidgets(2));
      // A second tap takes one back out.
      await tester.tap(find.text("실패"));
      await tester.tap(find.text("실패"));
      await tester.pumpAndSettle();
      expect(find.text("2개 선택"), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, "삭제"));
      await tester.pumpAndSettle();
      expect(
        find.text("통화 녹음 2개를 삭제하시겠습니까? 올린 파일까지 지워지며 되돌릴 수 없습니다."),
        findsOneWidget,
      );
      expect(recordings.deletes, isEmpty);
      recordings.deleting = Completer<void>();
      await tester.tap(confirm());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text("삭제하는 중"), findsOneWidget);
      expect(find.widgetWithText(FilledButton, "삭제"), findsNothing);
      // One at a time.
      expect(recordings.deletes, ["r2"]);
      recordings.deleting!.complete();
      await tester.pumpAndSettle();
      expect(recordings.deletes, ["r2", "r3"]);
      expect(find.text("녹음 2개를 삭제했습니다."), findsOneWidget);
      expect(find.text("통화 녹음 1"), findsOneWidget);
      expect(find.text("프레시팜"), findsNothing);
      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
      expect(find.byTooltip("녹음 삭제"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("취소 deletes nothing, in the title row or in the dialog", (
      tester,
    ) async {
      final recordings = three();
      await _pumpCase(tester, _Picker([]), recordings: recordings);
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("새벽딸기").first);
      await tester.pumpAndSettle();
      expect(find.text("1개 선택"), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, "삭제"));
      await tester.pumpAndSettle();
      expect(
        find.text("이 통화 녹음을 삭제하시겠습니까? 올린 파일까지 지워지며 되돌릴 수 없습니다."),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text("취소"),
        ),
      );
      await tester.pumpAndSettle();
      // Still choosing, with the choice kept.
      expect(find.text("1개 선택"), findsOneWidget);
      await tester.tap(find.text("취소"));
      await tester.pumpAndSettle();
      expect(find.text("통화 녹음 3"), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsNothing);
      // Choosing again starts empty.
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      expect(find.text("삭제할 녹음 선택"), findsOneWidget);
      expect(recordings.deletes, isEmpty);
    });

    testWidgets("leaving the case while it deletes still finishes cleanly", (
      tester,
    ) async {
      final recordings = three()..deleting = Completer<void>();
      await _pumpCase(tester, _Picker([]), recordings: recordings);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(CallRecordingSection)),
      );
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("프레시팜"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, "삭제"));
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pump();
      // The section goes away before the server answers.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: Scaffold(body: Text("다른 화면"))),
        ),
      );
      recordings.deleting!.complete();
      await tester.pumpAndSettle();
      expect(recordings.deletes, ["r2"]);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a slot freed by a delete opens the add tile at once", (
      tester,
    ) async {
      final recordings = _Recordings(maxPerCase: 2)
        ..items.addAll([_recording("r1"), _recording("r2", supplierId: "s1")]);
      final picker = _Picker([_file("통화.m4a", 1000)]);
      await _pumpCase(tester, picker, recordings: recordings);
      expect(find.text("업무 하나에 녹음은 2개까지 올릴 수 있습니다."), findsOneWidget);
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("프레시팜"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, "삭제"));
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(find.text("업무 하나에 녹음은 2개까지 올릴 수 있습니다."), findsNothing);
      await _choose(tester);
      expect(picker.picks, 1);
    });

    testWidgets("a lost answer is checked against the list, not assumed", (
      tester,
    ) async {
      // The server deleted r1, but the app never heard back.
      final recordings = three()..lostAnswers.add("r1");
      await _pumpCase(tester, _Picker([]), recordings: recordings);
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("업로드됨"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, "삭제"));
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(find.text("녹음 1개를 삭제했습니다."), findsOneWidget);
      expect(find.text("통화 녹음 2"), findsOneWidget);
    });

    testWidgets("the rows do not move when choosing starts", (tester) async {
      await _pumpCase(tester, _Picker([]), recordings: three());
      final before = tester.getTopLeft(find.text("프레시팜")).dy;
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text("프레시팜")).dy, before);
    });

    testWidgets("a recording the server refuses stays, and it says so", (
      tester,
    ) async {
      final recordings = three()..undeletable.add("r1");
      await _pumpCase(tester, _Picker([]), recordings: recordings);
      await tester.tap(find.byTooltip("녹음 삭제"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("업로드됨"));
      await tester.tap(find.text("프레시팜"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, "삭제"));
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(recordings.deletes, ["r1", "r2"]);
      expect(find.text("2개 중 1개를 삭제하지 못했습니다. 다시 시도해 주세요."), findsOneWidget);
      expect(find.text("통화 녹음 2"), findsOneWidget);
      expect(find.text("업로드됨"), findsOneWidget);
      expect(find.text("프레시팜"), findsNothing);
    });
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
