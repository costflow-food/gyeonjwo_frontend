/// 검토 진행 팝업의 단계. API-03 processing_step을 화면 단계로 묶습니다.
enum ReviewStage {
  extracting("요청 정보 추출"),
  findingCandidates("견적 요청 후보 찾기"),
  reviewingReplies("회신 검토"),
  preparingCard("검토 카드 준비");

  const ReviewStage(this.label);
  final String label;
}

/// 서버가 아직 처리 중인 단계. 이 단계 동안만 다시 조회합니다.
/// 그래프는 회신 검토부터 카드 생성까지 GENERATING_PLANS 하나로 알리고,
/// BUILDING_* 는 이전 실행 방식의 단계입니다.
const _running = {
  "PENDING_START": ReviewStage.extracting,
  "ACKNOWLEDGED": ReviewStage.extracting,
  "EXTRACTING": ReviewStage.extracting,
  "SELECTING_CANDIDATES": ReviewStage.findingCandidates,
  "GENERATING_PLANS": ReviewStage.reviewingReplies,
  "BUILDING_PLANS": ReviewStage.preparingCard,
  "BUILDING_COUNTER_OFFER": ReviewStage.preparingCard,
};

/// 멈춘 단계: 구매담당자가 확인하거나, 거래처 회신을 기다립니다.
enum ReviewOutcome {
  chooseCandidates(
    "견적을 요청할 업체를 골라 주세요.",
    reached: ReviewStage.findingCandidates,
  ),
  waitingApproval(
    "견적 요청 초안이 준비됐어요. 확인한 뒤 승인해 주세요.",
    reached: ReviewStage.findingCandidates,
  ),
  waitingReply(
    "견적 요청을 보냈어요. 거래처 회신이 오면 이어서 검토해요.",
    reached: ReviewStage.findingCandidates,
  ),
  reviewReady("검토 카드가 준비됐어요.", reached: ReviewStage.preparingCard),
  sendUnknown("발송 결과를 확인해야 해요.", stopped: true),
  onHold("검토를 보류했어요.", stopped: true),
  needsInfo("추가 정보 확인이 필요해요.", stopped: true),
  failed("처리 중 오류가 났어요. 업무에서 상태를 확인해 주세요.", stopped: true),
  other("업무에서 현재 상태를 확인해 주세요.");

  const ReviewOutcome(this.message, {this.reached, this.stopped = false});
  final String message;

  /// 정상적으로 멈춘 경우 마친 마지막 단계.
  final ReviewStage? reached;

  /// 문제가 있어 멈춘 결과. 화면에서 강조합니다.
  final bool stopped;
}

ReviewStage? runningStage(String step) => _running[step];

/// 처리 중이면 null.
ReviewOutcome? outcomeOf(String step) => switch (step) {
  _ when _running.containsKey(step) => null,
  "CANDIDATES" => ReviewOutcome.chooseCandidates,
  "WAITING_APPROVAL" || "AWAITING_APPROVAL" => ReviewOutcome.waitingApproval,
  "WAITING_REPLY" => ReviewOutcome.waitingReply,
  "REVIEW_READY" => ReviewOutcome.reviewReady,
  "SEND_UNKNOWN" => ReviewOutcome.sendUnknown,
  "ON_HOLD" => ReviewOutcome.onHold,
  "NEEDS_INFO" => ReviewOutcome.needsInfo,
  "FAILED" => ReviewOutcome.failed,
  _ => ReviewOutcome.other,
};

enum StageState { done, running, stopped, waiting }

/// 단계별 표시. [lastRunning]은 이 팝업에서 마지막으로 본 처리 중 단계로,
/// 보류·실패가 어느 단계에서 났는지 정할 때 씁니다.
List<StageState> stageStates(
  String step, {
  String? stopCode,
  ReviewStage? lastRunning,
}) {
  List<StageState> upTo(ReviewStage at, StageState current) => [
    for (final stage in ReviewStage.values)
      stage.index < at.index
          ? StageState.done
          : stage == at
          ? current
          : StageState.waiting,
  ];
  final running = runningStage(step);
  if (running != null) return upTo(running, StageState.running);
  final outcome = outcomeOf(step)!;
  if (outcome.stopped) {
    final guess = _stoppedAt(outcome, stopCode);
    final at = lastRunning != null && lastRunning.index > guess.index
        ? lastRunning
        : guess;
    return upTo(at, StageState.stopped);
  }
  final reached = outcome.reached ?? lastRunning;
  if (reached == null) {
    return [for (final _ in ReviewStage.values) StageState.waiting];
  }
  return upTo(reached, StageState.done);
}

/// 팝업을 늦게 열어 처리 중 단계를 못 봤을 때의 추정.
ReviewStage _stoppedAt(ReviewOutcome outcome, String? stopCode) =>
    switch (stopCode) {
      "NO_SUITABLE_CANDIDATES" ||
      "NO_REGISTERED_SUPPLIER_EVIDENCE" ||
      "RFQ_CONDITIONS_REQUIRED" ||
      "SEND_POLICY_REQUIRED" => ReviewStage.findingCandidates,
      _ when outcome == ReviewOutcome.sendUnknown =>
        ReviewStage.findingCandidates,
      _ => ReviewStage.extracting,
    };
