import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/case_stage.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_state.dart";

WorkCase _case(
  String status,
  String step, {
  int revision = 1,
  bool archived = false,
  List<String> allowed = const [],
  String? blockedCandidates,
  String? holdCode,
  ReplySummary? replies,
  String? item,
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
  itemName: item,
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
    // 결정 (b): 검토 시작 전만 '대기', 보류·오류·완료가 아니면 '진행 중'.
    // 결정 (a): n은 접수 · 정보 추출 · 후보 찾기 · 견적 요청·회신 · 검토 카드.
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
        2,
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
        3,
      ),
      "user picks suppliers": (
        _case(
          "Running",
          "CANDIDATES",
          allowed: [WorkCaseAction.selectCandidates],
        ),
        TaskGroup.confirm,
        TaskLabel.running,
        3,
      ),
      "candidates not ready yet": (
        _case(
          "Running",
          "CANDIDATES",
          blockedCandidates: "CANDIDATES_NOT_READY",
        ),
        TaskGroup.running,
        TaskLabel.running,
        4,
      ),
      "no candidate can be picked": (
        _case(
          "Running",
          "CANDIDATES",
          blockedCandidates: "INVALID_CANDIDATE_SELECTION",
        ),
        TaskGroup.confirm,
        TaskLabel.running,
        3,
      ),
      "server drafting the quote requests": (
        _case("Running", "CANDIDATES"),
        TaskGroup.running,
        TaskLabel.running,
        4,
      ),
      "waiting for replies": (
        _case("Running", "WAITING_REPLY"),
        TaskGroup.running,
        TaskLabel.running,
        4,
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
        TaskLabel.running,
        4,
      ),
      "draft waits for approval (old code)": (
        _case("Pending", "AWAITING_APPROVAL"),
        TaskGroup.confirm,
        TaskLabel.running,
        4,
      ),
      "needs info, item not read": (
        _case("Pending", "NEEDS_INFO"),
        TaskGroup.confirm,
        TaskLabel.hold,
        2,
      ),
      "needs info, item read": (
        _case("Pending", "NEEDS_INFO", item: "냉동 딸기"),
        TaskGroup.confirm,
        TaskLabel.hold,
        3,
      ),
      "held: no candidates": (
        _case("Pending", "ON_HOLD", holdCode: "NO_SUITABLE_CANDIDATES"),
        TaskGroup.confirm,
        TaskLabel.hold,
        3,
      ),
      "held: supplier mismatch": (
        _case("Pending", "ON_HOLD", holdCode: "SUPPLIER_MISMATCH"),
        TaskGroup.confirm,
        TaskLabel.hold,
        2,
      ),
      "held: no quote data": (
        _case("Pending", "ON_HOLD", holdCode: "NO_QUOTE_DATA"),
        TaskGroup.confirm,
        TaskLabel.hold,
        4,
      ),
      "held without a reason, after quote requests": (
        _case(
          "Pending",
          "ON_HOLD",
          replies: const ReplySummary(requested: 2, responded: 0),
        ),
        TaskGroup.confirm,
        TaskLabel.hold,
        4,
      ),
      "processing failed before the item was read": (
        _case("Pending", "FAILED"),
        TaskGroup.confirm,
        TaskLabel.error,
        2,
      ),
      "processing failed after replies": (
        _case(
          "Pending",
          "FAILED",
          item: "냉동 딸기",
          replies: const ReplySummary(requested: 3, responded: 2),
        ),
        TaskGroup.confirm,
        TaskLabel.error,
        5,
      ),
      "send result unknown": (
        _case("Pending", "SEND_UNKNOWN"),
        TaskGroup.confirm,
        TaskLabel.error,
        4,
      ),
      "review card ready": (
        _case("Complete", "REVIEW_READY"),
        TaskGroup.confirm,
        TaskLabel.running,
        5,
      ),
      "plan confirmed (archived)": (
        _case("Complete", "REVIEW_READY", archived: true),
        TaskGroup.complete,
        TaskLabel.done,
        CaseStage.total,
      ),
      "unknown status": (
        _case("Mystery", "SOMETHING"),
        TaskGroup.confirm,
        TaskLabel.running,
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
    expect(taskProgressOf(workCase), 2);
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

  test("groups in 가나다 order, 품목 미확인 last; 전체 includes 완료", () {
    final active = [
      _case("Running", "WAITING_REPLY", item: "제주감귤"),
      _case("Waiting", "PENDING_START"),
      _case("Running", "WAITING_REPLY", item: "깐마늘"),
    ];
    final done = [
      _case("Complete", "REVIEW_READY", item: "냉동 딸기", archived: true),
    ];
    final all = groupCases(tabCases(null, active: active, completed: done));
    expect(all.map((group) => group.itemName), ["깐마늘", "냉동 딸기", "제주감귤", null]);
    expect(tabCases(TaskGroup.complete, active: active, completed: done), done);
    expect(
      tabCases(TaskGroup.running, active: active, completed: done).length,
      2,
    );
    // Folded groups are skipped in the row order.
    expect(orderedCases(all, collapsed: {"깐마늘"}).first.itemName, "냉동 딸기");
  });
}
