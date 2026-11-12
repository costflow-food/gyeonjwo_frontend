import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/candidate.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";

CandidateSet _set({
  String? reasonCode,
  bool stale = false,
  List<String> selected = const [],
  bool allowed = false,
}) => CandidateSet(
  id: "set-1",
  revision: 1,
  candidates: const [],
  isStale: stale,
  selectedSupplierIds: selected,
  allowedActions: [if (allowed) WorkCaseAction.selectCandidates],
  disabledActions: [
    if (reasonCode != null)
      DisabledWorkCaseAction(
        action: WorkCaseAction.selectCandidates,
        reasonCode: reasonCode,
        message: "서버 문구",
      ),
  ],
);

void main() {
  test(
    "a server with selection switched off only blocks, without a notice",
    () {
      for (final code in const [
        "CANDIDATE_SELECTION_INTEGRATION_REQUIRED",
        "PROCESSING_UNAVAILABLE",
      ]) {
        expect(_set(reasonCode: code).serverBlocked, isTrue, reason: code);
      }
    },
  );

  test("any other reason keeps the server's own message", () {
    final set = _set(reasonCode: "CASE_ON_HOLD");
    expect(set.serverBlocked, isFalse);
    expect(set.blockedReason, "서버 문구");
  });

  test("past candidates, a saved choice and an open selection are not it", () {
    const code = "PROCESSING_UNAVAILABLE";
    expect(_set(reasonCode: code, stale: true).serverBlocked, isFalse);
    expect(_set(reasonCode: code, selected: ["s1"]).serverBlocked, isFalse);
    expect(_set(reasonCode: code, allowed: true).serverBlocked, isFalse);
    expect(_set().serverBlocked, isFalse);
  });
}
