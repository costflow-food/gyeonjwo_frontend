import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/case_stage.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";

WorkCase _case(
  String step, {
  String status = "Running",
  int revision = 1,
  List<String> actions = const [],
  String? blockedBy,
  ReplySummary? replies,
  String? item,
  String? holdCode,
  bool archived = false,
}) => WorkCase(
  id: "c1",
  initialMailId: "m1",
  title: "제목",
  sender: "a@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: "",
  inputRevision: revision,
  attachmentCount: 0,
  itemName: item,
  archived: archived,
  allowedActions: actions,
  replySummary: replies,
  hold: holdCode == null ? null : HoldReason(code: holdCode, message: "사유"),
  disabledActions: [
    if (blockedBy != null)
      DisabledWorkCaseAction(
        action: WorkCaseAction.selectCandidates,
        reasonCode: blockedBy,
        message: "",
      ),
  ],
);

void main() {
  test("five steps as in the design", () {
    expect(caseStepNames, ["접수", "정보 추출", "후보 찾기", "견적 요청·회신", "검토 카드"]);
  });

  // 결정 (a): 서버 processing_step → 다섯 단계.
  test("server steps map onto the five steps", () {
    const table = {
      "PENDING_START": 1,
      "ACKNOWLEDGED": 1,
      "EXTRACTING": 2,
      "SELECTING_CANDIDATES": 3,
      "WAITING_APPROVAL": 4,
      "AWAITING_APPROVAL": 4,
      "SEND_UNKNOWN": 4,
      "WAITING_REPLY": 4,
      "GENERATING_PLANS": 5,
      "BUILDING_PLANS": 5,
      "BUILDING_COUNTER_OFFER": 5,
      "REVIEW_READY": 5,
    };
    for (final MapEntry(key: step, value: index) in table.entries) {
      expect(caseStageOf(_case(step))!.index, index, reason: step);
    }
    expect(caseStageOf(_case("SOMETHING_NEW")), isNull);
  });

  test("candidate pick is step 3; the server drafting requests is step 4", () {
    expect(
      caseStageOf(
        _case("CANDIDATES", actions: [WorkCaseAction.selectCandidates]),
      )!.index,
      3,
    );
    expect(caseStageOf(_case("CANDIDATES"))!.index, 4);
    expect(
      caseStageOf(_case("CANDIDATES", blockedBy: "CANDIDATES_NOT_READY"))!
          .index,
      4,
    );
  });

  test("reading a reply is step 4 only after a quote request went out", () {
    expect(caseStageOf(_case("EXTRACTING", revision: 2))!.index, 4);
    expect(
      caseStageOf(
        _case(
          "EXTRACTING",
          revision: 2,
          replies: const ReplySummary(requested: 0, responded: 0),
        ),
      )!.index,
      2,
    );
  });

  test("a stop follows its reason code, else what the list knows", () {
    expect(caseStageOf(_case("ON_HOLD", holdCode: "MISSING_FIELD"))!.index, 2);
    expect(
      caseStageOf(_case("NEEDS_INFO"), stopCode: "SEND_POLICY_REQUIRED")!.index,
      4,
    );
    expect(caseStageOf(_case("ON_HOLD"))!.index, 2);
    expect(caseStageOf(_case("ON_HOLD", item: "깐마늘"))!.index, 3);
  });

  test("a failure keeps its step and marks it as an error", () {
    final failed = caseStageOf(
      _case(
        "FAILED",
        item: "깐마늘",
        replies: const ReplySummary(requested: 3, responded: 0),
      ),
    )!;
    expect(failed.index, 4);
    expect(failed.error, isTrue);
    expect(failed.doneCount, 3);
    expect(failed.semanticsLabel, "5단계 중 4단계 견적 요청·회신, 오류");
    expect(
      caseStageOf(_case("FAILED"), stopCode: "RFQ_PREPARATION_FAILED")!.index,
      4,
    );
    expect(caseStageOf(_case("WAITING_REPLY"))!.error, isFalse);
  });

  test("a confirmed plan finishes every step", () {
    final done = caseStageOf(_case("REVIEW_READY", archived: true))!;
    expect(done.complete, isTrue);
    expect(done.index, CaseStage.total);
    expect(done.doneCount, CaseStage.total);
    expect(done.semanticsLabel, "5단계 모두 완료");
  });
}
