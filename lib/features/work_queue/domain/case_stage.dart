import "task_group.dart";
import "work_case.dart";

/// 업무 진행 다섯 단계 (Tasks 시안): 목록 행의 n/5와 상세 단계 바가 같은
/// 기준입니다.
const caseStepNames = ["접수", "정보 추출", "후보 찾기", "견적 요청·회신", "검토 카드"];

/// 업무가 다섯 단계 중 어디에 있는지.
class CaseStage {
  const CaseStage({
    required this.index,
    this.complete = false,
    this.error = false,
  });

  static const total = 5;

  /// 1부터 센 지금 단계. 완료면 [total].
  final int index;

  /// 구매안을 확정해 모든 단계를 마쳤습니다.
  final bool complete;

  /// 지금 단계에서 오류가 났습니다(처리 오류·발송 결과 모름).
  final bool error;

  /// 끝난 단계 수.
  int get doneCount => complete ? total : index - 1;

  String get name => caseStepNames[index - 1];

  String get semanticsLabel => complete
      ? "$total단계 모두 완료"
      : "$total단계 중 $index단계 $name${error ? ", 오류" : ""}";

  @override
  bool operator ==(Object other) =>
      other is CaseStage &&
      other.index == index &&
      other.complete == complete &&
      other.error == error;

  @override
  int get hashCode => Object.hash(index, complete, error);

  @override
  String toString() =>
      "CaseStage($index/$total${complete ? ", complete" : ""}"
      "${error ? ", error" : ""})";
}

/// 서버 단계 코드 → 단계(1 접수 · 2 정보 추출 · 3 후보 찾기 · 4 견적 요청·회신 ·
/// 5 검토 카드). 보류·처리 오류·사유 필요(NEEDS_INFO)는 따로 고릅니다.
const _stepStages = {
  "PENDING_START": 1,
  "ACKNOWLEDGED": 1,
  "EXTRACTING": 2,
  "SELECTING_CANDIDATES": 3,
  "CANDIDATES": 3,
  "WAITING_APPROVAL": 4,
  "AWAITING_APPROVAL": 4,
  "SEND_UNKNOWN": 4,
  "WAITING_REPLY": 4,
  "GENERATING_PLANS": 5,
  "BUILDING_PLANS": 5,
  "BUILDING_COUNTER_OFFER": 5,
  "REVIEW_READY": 5,
};

/// 멈춘 이유 코드(보류 hold.code · API-03 error.code)로 아는 단계.
const _stopStages = {
  "SUPPLIER_NOT_MATCHED": 2,
  "SUPPLIER_MISMATCH": 2,
  "MISSING_FIELD": 2,
  "MISSING_EVIDENCE": 2,
  "SOURCE_READ_FAILED": 2,
  "NO_SUITABLE_CANDIDATES": 3,
  "NO_REGISTERED_SUPPLIER_EVIDENCE": 3,
  "RFQ_CONDITIONS_REQUIRED": 4,
  "CONDITIONS_MISSING": 4,
  "SEND_POLICY_REQUIRED": 4,
  "RFQ_PREPARATION_FAILED": 4,
  "NO_QUOTE_DATA": 4,
  "COUNTER_OFFER_POLICY_MISSING": 5,
  "COUNTER_OFFER_NOT_COMPUTABLE": 5,
};

/// 오류로 보이는 단계 코드. 단계 바의 지금 단계를 빨간 원으로 그립니다.
const _errorSteps = {"FAILED", "SEND_UNKNOWN"};

/// 업무의 지금 단계. 모르는 단계 코드면 null(행의 n/5를 비웁니다).
///
/// [stopCode]는 API-03의 멈춘 이유 코드입니다. 목록은 보류(ON_HOLD)에만
/// 사유를 실어 보내므로, 사유를 모르는 멈춤·오류는 목록에 있는 것(품목,
/// 견적 요청·회신 수)으로 짐작합니다.
CaseStage? caseStageOf(WorkCase workCase, {String? stopCode}) {
  if (workCase.archived) {
    return const CaseStage(index: CaseStage.total, complete: true);
  }
  final step = workCase.processingStep;
  final error = _errorSteps.contains(step);
  final replies = workCase.replySummary;
  // 견적 요청이 나갔는지. API-02로 읽은 업무는 회신 현황이 없어 모릅니다(null).
  final rfqSent = replies?.visible;
  int guess() {
    if ((replies?.responded ?? 0) > 0) return step == "FAILED" ? 5 : 4;
    if (rfqSent ?? false) return 4;
    if (workCase.itemName == null) return 2;
    return step == "FAILED" ? 4 : 3;
  }

  final index = switch (step) {
    // 연결된 회신을 읽는 중: 견적 요청·회신 단계.
    "EXTRACTING"
        when isReplyExtraction(step, workCase.inputRevision) &&
            (rfqSent ?? true) =>
      4,
    // 서버가 견적 요청을 준비하는 중(사용자가 고를 차례가 아님).
    ProcessingStep.candidates when !userPicksCandidates(workCase) =>
      _preparingRfq(workCase) ? 4 : 3,
    ProcessingStep.onHold ||
    ProcessingStep.needsInfo ||
    "FAILED" => _stopStages[stopCode ?? workCase.hold?.code] ?? guess(),
    _ => _stepStages[step],
  };
  if (index == null) return null;
  return CaseStage(index: index, error: error);
}

/// CANDIDATES에서 막힌 이유가 없거나 후보를 아직 찾는 중: 서버가 견적 요청을
/// 준비합니다(옛 경로).
bool _preparingRfq(WorkCase workCase) {
  final blocked = workCase.disabledActions
      .where((disabled) => disabled.action == WorkCaseAction.selectCandidates)
      .firstOrNull;
  return blocked == null || blocked.reasonCode == "CANDIDATES_NOT_READY";
}
