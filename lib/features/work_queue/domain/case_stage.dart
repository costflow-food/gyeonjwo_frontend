import "work_case.dart";

/// Where a case stands in the five-slice flow shown on a queue card:
/// 1 요청 확인 → 2 후보 → 3 견적 요청 → 4 회신 → 5 검토.
class CaseStage {
  const CaseStage({
    required this.index,
    required this.working,
    required this.label,
    this.ownSliceOpen = false,
  });

  static const total = 5;

  /// 1-based slice the case is in.
  final int index;

  /// The AI is working on [index] right now. False while it rests and the
  /// user or a supplier has the next move.
  final bool working;

  final String label;

  /// Resting, but [index] itself is not finished yet: the quote request is
  /// drafted and waits for approval, or its send result is unknown.
  final bool ownSliceOpen;

  /// Slices drawn as finished. A resting case has finished its own slice,
  /// unless [ownSliceOpen].
  int get doneCount => working || ownSliceOpen ? index - 1 : index;

  String get semanticsLabel =>
      "$total단계 중 $index단계 ${working ? "작업 중" : "대기"}, $label";

  @override
  bool operator ==(Object other) =>
      other is CaseStage &&
      other.index == index &&
      other.working == working &&
      other.label == label &&
      other.ownSliceOpen == ownSliceOpen;

  @override
  int get hashCode => Object.hash(index, working, label, ownSliceOpen);

  @override
  String toString() =>
      "CaseStage($index/$total, working: $working, done: $doneCount, $label)";
}

/// Slice and whether the AI is the one acting, per processing step.
const _stages = <String, (int, bool)>{
  "EXTRACTING": (1, true),
  "SELECTING_CANDIDATES": (2, true),
  "CANDIDATES": (2, false),
  "WAITING_APPROVAL": (3, false),
  "AWAITING_APPROVAL": (3, false),
  "SEND_UNKNOWN": (3, false),
  "WAITING_REPLY": (3, false),
  "GENERATING_PLANS": (5, true),
  "REVIEW_READY": (5, false),
};

/// Resting steps whose quote request has not (verifiably) gone out.
const _unsent = {"WAITING_APPROVAL", "AWAITING_APPROVAL", "SEND_UNKNOWN"};

/// Null hides the ring: steps before the review starts (PENDING_START,
/// ACKNOWLEDGED), steps the server no longer writes (BUILDING_*), stops whose
/// slice the list API cannot tell (ON_HOLD, NEEDS_INFO, FAILED), and any code
/// this app does not know.
///
/// [canSelectCandidates] is whether the server offers SELECT_CANDIDATES; only
/// then is CANDIDATES really waiting on the user's pick.
///
/// [preparingRfq]: at CANDIDATES the worker is already drafting or sending the
/// quote requests (the server's legacy path), so the third slice is working.
///
/// [rfqSent] false means no quote request went out this round, so a raised
/// revision cannot be a supplier reply.
CaseStage? caseStageOf(
  String step, {
  int inputRevision = 1,
  bool canSelectCandidates = false,
  bool preparingRfq = false,
  bool rfqSent = true,
}) {
  if (!rfqSent) inputRevision = 1;
  // A reply arrived and is being read: the reply slice, not the first one.
  if (isReplyExtraction(step, inputRevision)) {
    return CaseStage(
      index: 4,
      working: true,
      label: processingStepLabel(step, inputRevision: inputRevision),
    );
  }
  if (step == ProcessingStep.candidates &&
      preparingRfq &&
      !canSelectCandidates) {
    return CaseStage(index: 3, working: true, label: processingStepLabel(step));
  }
  final stage = _stages[step];
  if (stage == null) return null;
  return CaseStage(
    index: stage.$1,
    working: stage.$2,
    ownSliceOpen: _unsent.contains(step),
    // The shared table words these two from the worker's side ("후보 찾기
    // 대기", "견적 요청 준비 중"), which contradicts who is acting here.
    label: switch (step) {
      "SELECTING_CANDIDATES" => "후보 찾는 중",
      "CANDIDATES" when canSelectCandidates => "업체 선택 대기",
      _ => processingStepLabel(step, inputRevision: inputRevision),
    },
  );
}

/// The ring for a queue row. Only cases in the 진행 중 tab (Running, Pending)
/// get one; 대기 and 완료 are covered by the status badge.
CaseStage? ringStageOf(WorkCase workCase) {
  if (workCase.status.tab != WorkCaseStatus.running) return null;
  final blocked = workCase.disabledActions
      .where((disabled) => disabled.action == WorkCaseAction.selectCandidates)
      .firstOrNull;
  return caseStageOf(
    workCase.processingStep,
    inputRevision: workCase.inputRevision,
    canSelectCandidates: workCase.can(WorkCaseAction.selectCandidates),
    // Not offered and not blocked for another reason (missing integration,
    // already picked): the worker went straight on to the quote requests.
    preparingRfq:
        blocked == null || blocked.reasonCode == "CANDIDATES_NOT_READY",
    // Null (a case read through API-02) tells nothing; trust the revision.
    rfqSent: workCase.replySummary?.visible ?? true,
  );
}
