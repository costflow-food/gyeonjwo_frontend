import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/case_stage.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";

WorkCase _case(
  String status,
  String step, {
  int revision = 1,
  bool archived = false,
  List<String> allowed = const [],
  String? blockedCandidates,
  String? holdCode,
  ReplySummary? replies,
}) => WorkCase(
  id: "c",
  initialMailId: "m",
  title: "한라푸드",
  sender: "sales@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: step,
  inputRevision: revision,
  attachmentCount: 0,
  archived: archived,
  allowedActions: allowed,
  hold: holdCode == null ? null : HoldReason(code: holdCode, message: "사유"),
  replySummary: replies,
  disabledActions: [
    if (blockedCandidates != null)
      DisabledWorkCaseAction(
        action: WorkCaseAction.selectCandidates,
        reasonCode: blockedCandidates,
        message: "막힘",
      ),
  ],
);

void main() {
  // SSOT 7.14 'whose turn is it', by server status and step. The label shows
  // why a case is in its group; n is the slice of five on the row.
  group("status × step → group, label, progress", () {
    final table = <String, (WorkCase, TaskGroup, TaskLabel, int?)>{
      "not started": (
        _case("Waiting", "PENDING_START"),
        TaskGroup.confirm,
        TaskLabel.waiting,
        1,
      ),
      "mail acknowledged": (
        _case("Confirm", "ACKNOWLEDGED"),
        TaskGroup.confirm,
        TaskLabel.waiting,
        1,
      ),
      "first extraction": (
        _case("Running", "EXTRACTING"),
        TaskGroup.running,
        TaskLabel.running,
        1,
      ),
      "reading a supplier reply": (
        _case("Running", "EXTRACTING", revision: 2),
        TaskGroup.running,
        TaskLabel.running,
        4,
      ),
      "finding candidates": (
        _case("Running", "SELECTING_CANDIDATES"),
        TaskGroup.running,
        TaskLabel.running,
        2,
      ),
      "user picks suppliers": (
        _case(
          "Running",
          "CANDIDATES",
          allowed: [WorkCaseAction.selectCandidates],
        ),
        TaskGroup.confirm,
        TaskLabel.waiting,
        2,
      ),
      "candidates not ready yet": (
        _case(
          "Running",
          "CANDIDATES",
          blockedCandidates: "CANDIDATES_NOT_READY",
        ),
        TaskGroup.running,
        TaskLabel.running,
        2,
      ),
      "no candidate can be picked": (
        _case(
          "Running",
          "CANDIDATES",
          blockedCandidates: "INVALID_CANDIDATE_SELECTION",
        ),
        TaskGroup.confirm,
        TaskLabel.waiting,
        2,
      ),
      "server drafting the quote requests": (
        _case("Running", "CANDIDATES"),
        TaskGroup.running,
        TaskLabel.running,
        3,
      ),
      "waiting for replies": (
        _case("Running", "WAITING_REPLY"),
        TaskGroup.running,
        TaskLabel.running,
        3,
      ),
      "building plans": (
        _case("Running", "GENERATING_PLANS"),
        TaskGroup.running,
        TaskLabel.running,
        5,
      ),
      "draft waits for approval": (
        _case("Pending", "WAITING_APPROVAL"),
        TaskGroup.confirm,
        TaskLabel.waiting,
        3,
      ),
      "draft waits for approval (old code)": (
        _case("Pending", "AWAITING_APPROVAL"),
        TaskGroup.confirm,
        TaskLabel.waiting,
        3,
      ),
      "needs conditions": (
        _case("Pending", "NEEDS_INFO"),
        TaskGroup.confirm,
        TaskLabel.hold,
        3,
      ),
      "held: no candidates": (
        _case("Pending", "ON_HOLD", holdCode: "NO_SUITABLE_CANDIDATES"),
        TaskGroup.confirm,
        TaskLabel.hold,
        2,
      ),
      "held: supplier mismatch": (
        _case("Pending", "ON_HOLD", holdCode: "SUPPLIER_MISMATCH"),
        TaskGroup.confirm,
        TaskLabel.hold,
        1,
      ),
      "held without a reason": (
        _case("Pending", "ON_HOLD"),
        TaskGroup.confirm,
        TaskLabel.hold,
        null,
      ),
      "processing failed": (
        _case("Pending", "FAILED"),
        TaskGroup.confirm,
        TaskLabel.error,
        null,
      ),
      "send result unknown": (
        _case("Pending", "SEND_UNKNOWN"),
        TaskGroup.confirm,
        TaskLabel.error,
        3,
      ),
      // Complete only means the review card is ready: the user picks a plan.
      "review card ready": (
        _case("Complete", "REVIEW_READY"),
        TaskGroup.confirm,
        TaskLabel.waiting,
        5,
      ),
      // Confirming the plan archives the case.
      "plan confirmed (archived)": (
        _case("Complete", "REVIEW_READY", archived: true),
        TaskGroup.complete,
        TaskLabel.done,
        CaseStage.total,
      ),
      "unknown status": (
        _case("Mystery", "SOMETHING"),
        TaskGroup.confirm,
        TaskLabel.waiting,
        null,
      ),
    };
    for (final MapEntry(key: name, value: (workCase, group, label, n))
        in table.entries) {
      test(name, () {
        expect(taskGroupOf(workCase), group, reason: "group");
        expect(taskLabelOf(workCase), label, reason: "label");
        expect(taskProgressOf(workCase), n, reason: "n/5");
      });
    }
  });

  test("no quote request went out: a raised revision is not a reply", () {
    final workCase = _case(
      "Running",
      "EXTRACTING",
      revision: 2,
      replies: const ReplySummary(requested: 0, responded: 0),
    );
    expect(taskProgressOf(workCase), 1);
  });

  test("tab codes round-trip, and all/unknown mean the 전체 tab", () {
    for (final group in TaskGroup.values) {
      expect(TaskGroup.fromCode(group.code), group);
    }
    expect(TaskGroup.fromCode("all"), isNull);
    expect(TaskGroup.fromCode(null), isNull);
    expect(TaskGroup.fromCode("waiting"), isNull);
  });

  test("tab counts follow the groups; 완료 is counted elsewhere", () {
    final counts = WorkQueueCounts.fromCases([
      _case("Waiting", "PENDING_START"),
      _case("Complete", "REVIEW_READY"),
      _case("Running", "WAITING_REPLY"),
    ]);
    expect(counts.confirm, 2);
    expect(counts.running, 1);
    expect(counts.total, 3);
    expect(counts.countFor(null), 3);
    expect(counts.countFor(TaskGroup.complete), isNull);
    // With cases still on the server, the total is the server's.
    expect(
      WorkQueueCounts.fromCases([
        _case("Waiting", "PENDING_START"),
      ], serverTotal: 9).total,
      9,
    );
  });
}
