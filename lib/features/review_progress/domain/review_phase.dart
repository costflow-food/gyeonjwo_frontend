/// 검토 진행 팝업의 단계. API-03 processing_step을 화면 단계로 묶습니다.
enum ReviewStage {
  received("검토 접수"),
  extracting("요청 정보 추출"),
  findingCandidates("견적 요청 후보 찾기"),
  preparing("견적 요청 준비");

  const ReviewStage(this.label);
  final String label;
}

/// 서버가 아직 처리 중인 단계. 이 단계 동안만 다시 조회합니다.
const _running = {
  "PENDING_START": ReviewStage.received,
  "ACKNOWLEDGED": ReviewStage.received,
  "EXTRACTING": ReviewStage.extracting,
  "SELECTING_CANDIDATES": ReviewStage.findingCandidates,
  "GENERATING_PLANS": ReviewStage.preparing,
  "BUILDING_PLANS": ReviewStage.preparing,
  "BUILDING_COUNTER_OFFER": ReviewStage.preparing,
};

/// 멈춘 단계: 사용자가 확인하거나 결정할 차례입니다.
enum ReviewOutcome {
  chooseCandidates("견적을 요청할 업체를 골라 주세요."),
  waitingApproval("견적 요청 초안이 준비됐어요. 확인한 뒤 승인해 주세요."),
  onHold("검토를 보류했어요."),
  needsInfo("추가 정보 확인이 필요해요."),
  failed("처리 중 오류가 났어요. 업무에서 상태를 확인해 주세요."),
  done("검토가 끝났어요.");

  const ReviewOutcome(this.message);
  final String message;

  /// 문제가 있어 멈춘 결과. 화면에서 강조합니다.
  bool get stopped => this == onHold || this == needsInfo || this == failed;
}

ReviewStage? runningStage(String step) => _running[step];

/// 처리 중이면 null.
ReviewOutcome? outcomeOf(String step) => switch (step) {
  _ when _running.containsKey(step) => null,
  "CANDIDATES" => ReviewOutcome.chooseCandidates,
  "WAITING_APPROVAL" || "AWAITING_APPROVAL" => ReviewOutcome.waitingApproval,
  "ON_HOLD" => ReviewOutcome.onHold,
  "NEEDS_INFO" => ReviewOutcome.needsInfo,
  "FAILED" || "SEND_UNKNOWN" => ReviewOutcome.failed,
  _ => ReviewOutcome.done,
};

/// 멈춘 결과가 몇 번째 단계까지 왔는지(진행 표시용).
/// 후보 없음은 추출을 마친 뒤 후보 찾기에서 멈춘 것이라 그 단계에 표시합니다.
ReviewStage reachedStage(ReviewOutcome outcome, {String? errorCode}) =>
    switch (outcome) {
      ReviewOutcome.chooseCandidates => ReviewStage.findingCandidates,
      ReviewOutcome.waitingApproval || ReviewOutcome.done => ReviewStage.preparing,
      _ when errorCode == "NO_SUITABLE_CANDIDATES" =>
        ReviewStage.findingCandidates,
      ReviewOutcome.onHold ||
      ReviewOutcome.needsInfo ||
      ReviewOutcome.failed => ReviewStage.extracting,
    };
