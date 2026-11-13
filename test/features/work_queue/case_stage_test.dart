import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/case_stage.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";

WorkCase _case(
  String status,
  String step, {
  int revision = 1,
  List<String> actions = const [],
  String? blockedBy,
  ReplySummary? replies,
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
  allowedActions: actions,
  replySummary: replies,
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
  test("every step the AI runs is a working slice", () {
    expect(
      caseStageOf("EXTRACTING"),
      const CaseStage(index: 1, working: true, label: "요청 정보 확인 중"),
    );
    expect(
      caseStageOf("SELECTING_CANDIDATES"),
      const CaseStage(index: 2, working: true, label: "후보 찾는 중"),
    );
    expect(
      caseStageOf("GENERATING_PLANS"),
      const CaseStage(index: 5, working: true, label: "검토안 생성 중"),
    );
  });

  test("reading a supplier reply works on the reply slice", () {
    expect(
      caseStageOf("EXTRACTING", inputRevision: 2),
      const CaseStage(index: 4, working: true, label: "거래처 회신 확인 중"),
    );
    // Only EXTRACTING moves with the revision.
    expect(caseStageOf("WAITING_REPLY", inputRevision: 2)!.index, 3);
  });

  test("steps waiting on the user or a supplier rest", () {
    // Step → slice, finished slices, label.
    const resting = {
      "CANDIDATES": (2, 2, "견적 요청 준비 중"),
      // Not sent yet: the quote-request slice itself stays open.
      "WAITING_APPROVAL": (3, 2, "발송 승인 대기"),
      "AWAITING_APPROVAL": (3, 2, "발송 승인 대기"),
      "SEND_UNKNOWN": (3, 2, "발송 결과 확인 필요"),
      "WAITING_REPLY": (3, 3, "거래처 회신 대기"),
      "REVIEW_READY": (5, 5, "검토 결과 준비 완료"),
    };
    for (final MapEntry(key: step, value: (index, done, label))
        in resting.entries) {
      final stage = caseStageOf(step)!;
      expect(stage.index, index, reason: step);
      expect(stage.working, isFalse, reason: step);
      expect(stage.doneCount, done, reason: step);
      expect(stage.label, label, reason: step);
    }
    expect(
      caseStageOf("CANDIDATES", canSelectCandidates: true)!.label,
      "업체 선택 대기",
    );
  });

  test("a raised revision is a reply only after a quote request went out", () {
    const working1 = CaseStage(index: 1, working: true, label: "요청 정보 확인 중");
    const working4 = CaseStage(index: 4, working: true, label: "거래처 회신 확인 중");
    expect(
      ringStageOf(
        _case(
          "Running",
          "EXTRACTING",
          revision: 2,
          replies: const ReplySummary(requested: 0, responded: 0),
        ),
      ),
      working1,
    );
    expect(
      ringStageOf(
        _case(
          "Running",
          "EXTRACTING",
          revision: 2,
          replies: const ReplySummary(requested: 3, responded: 1),
        ),
      ),
      working4,
    );
    // No reply summary (API-02): the revision alone decides.
    expect(ringStageOf(_case("Running", "EXTRACTING", revision: 2)), working4);
  });

  test("CANDIDATES without a pick to wait for is the worker preparing", () {
    const preparing = CaseStage(index: 3, working: true, label: "견적 요청 준비 중");
    expect(ringStageOf(_case("Running", "CANDIDATES")), preparing);
    expect(
      ringStageOf(
        _case("Running", "CANDIDATES", blockedBy: "CANDIDATES_NOT_READY"),
      ),
      preparing,
    );
    expect(preparing.doneCount, 2);
    // Blocked for another reason: nothing is running.
    expect(
      ringStageOf(
        _case(
          "Running",
          "CANDIDATES",
          blockedBy: "CANDIDATE_SELECTION_INTEGRATION_REQUIRED",
        ),
      ),
      const CaseStage(index: 2, working: false, label: "견적 요청 준비 중"),
    );
    // The flag only matters at CANDIDATES.
    expect(ringStageOf(_case("Running", "WAITING_REPLY"))!.working, isFalse);
  });

  test("steps without a known slice have no ring", () {
    for (final step in [
      "PENDING_START",
      "ACKNOWLEDGED",
      "BUILDING_PLANS",
      "BUILDING_COUNTER_OFFER",
      "ON_HOLD",
      "NEEDS_INFO",
      "FAILED",
      "SOMETHING_NEW",
      "",
    ]) {
      expect(caseStageOf(step), isNull, reason: step);
      expect(caseStageOf(step, inputRevision: 3), isNull, reason: step);
    }
  });

  test("finished slices and the spoken label follow working or resting", () {
    final working = caseStageOf("SELECTING_CANDIDATES")!;
    expect(working.doneCount, 1);
    expect(working.semanticsLabel, "5단계 중 2단계 작업 중, 후보 찾는 중");
    final resting = caseStageOf("WAITING_REPLY")!;
    expect(resting.doneCount, 3);
    expect(resting.semanticsLabel, "5단계 중 3단계 대기, 거래처 회신 대기");
  });

  test("only cases in the running tab get a ring", () {
    expect(ringStageOf(_case("Running", "EXTRACTING"))!.index, 1);
    expect(ringStageOf(_case("Pending", "WAITING_APPROVAL"))!.index, 3);
    expect(
      ringStageOf(
        _case("Running", "CANDIDATES", actions: ["SELECT_CANDIDATES"]),
      )!.label,
      "업체 선택 대기",
    );
    expect(ringStageOf(_case("Waiting", "PENDING_START")), isNull);
    expect(ringStageOf(_case("Confirm", "ACKNOWLEDGED")), isNull);
    expect(ringStageOf(_case("Complete", "REVIEW_READY")), isNull);
    expect(ringStageOf(_case("Archived", "EXTRACTING")), isNull);
    expect(ringStageOf(_case("Running", "FAILED")), isNull);
    expect(ringStageOf(_case("Pending", "ON_HOLD")), isNull);
  });
}
