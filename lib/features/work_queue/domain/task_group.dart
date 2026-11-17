import "case_stage.dart";
import "work_case.dart";

/// 업무 상태 묶음 (`docs/design-ssot.md` 7.14): '누가 움직일 차례인가'.
///
/// Tasks 상태 탭과 Dashboard 상태 카드가 모두 [taskGroupOf] 하나로 나눕니다.
/// 서버 상태만으로는 나눌 수 없어 단계 코드와 후보 선택 가능 여부까지 봅니다.
/// 서버에 이 묶음의 필터·건수가 생기면(백엔드 요청) 그 값으로 바꿉니다.
enum TaskGroup {
  /// 사용자 차례: 검토 시작 전, 보류, 오류, 업체·구매안 선택, 발송 승인.
  confirm("confirm", "확인 필요"),

  /// 시스템이나 거래처 차례: 정보 추출, 후보 찾기, 회신 기다림, 검토안 생성.
  running("running", "진행 중"),

  /// 구매안 확정. 서버는 확정한 업무를 보관(archived)합니다.
  complete("complete", "완료");

  const TaskGroup(this.code, this.label);

  /// `/tasks?tab=` 값.
  final String code;
  final String label;

  /// `?tab=` 값으로 찾습니다. `all`·없음·모르는 값은 null(전체)입니다.
  static TaskGroup? fromCode(String? code) =>
      values.where((group) => group.code == code).firstOrNull;
}

/// 시스템이 일하는 단계. 나머지 진행 중인 업무는 사용자 차례입니다.
const _systemSteps = {
  "EXTRACTING",
  "SELECTING_CANDIDATES",
  "GENERATING_PLANS",
  "BUILDING_PLANS",
  "BUILDING_COUNTER_OFFER",
  "WAITING_REPLY",
};

/// CANDIDATES에서 후보 선택이 막힌 이유 중 시스템이 아직 준비 중인 것.
const _candidatesPreparing = {"CANDIDATES_NOT_READY", "REVISION_CONFLICT"};

/// CANDIDATES 단계에서 사용자가 고를 차례인지. 서버가 후보 선택을 열었거나,
/// 고를 수 있는 후보가 없는 등 사용자가 풀어야 하는 이유로 막혔을 때입니다.
/// 막힌 이유가 없으면 서버가 이미 견적 요청을 준비하는 중입니다.
bool _userPicksCandidates(WorkCase workCase) {
  if (workCase.can(WorkCaseAction.selectCandidates)) return true;
  final blocked = workCase.disabledActions
      .where((disabled) => disabled.action == WorkCaseAction.selectCandidates)
      .firstOrNull;
  return blocked != null && !_candidatesPreparing.contains(blocked.reasonCode);
}

TaskGroup taskGroupOf(WorkCase workCase) {
  if (workCase.archived) return TaskGroup.complete;
  final step = workCase.processingStep;
  if (step == ProcessingStep.candidates) {
    return _userPicksCandidates(workCase)
        ? TaskGroup.confirm
        : TaskGroup.running;
  }
  if (workCase.status == WorkCaseStatus.running &&
      _systemSteps.contains(step)) {
    return TaskGroup.running;
  }
  // Waiting·Confirm(검토 시작 전), Pending(승인 대기·보류·오류·발송 확인),
  // Complete/REVIEW_READY(검토 카드에서 구매안 선택), 모르는 상태.
  return TaskGroup.confirm;
}

/// 행·상세의 상태 라벨: 왜 그 묶음인지 보여 줍니다(7.14).
enum TaskLabel {
  waiting("대기"),
  hold("보류"),
  error("오류"),
  running("진행 중"),
  done("완료");

  const TaskLabel(this.text);
  final String text;
}

TaskLabel taskLabelOf(WorkCase workCase) {
  if (workCase.archived) return TaskLabel.done;
  return switch (workCase.processingStep) {
    ProcessingStep.onHold || ProcessingStep.needsInfo => TaskLabel.hold,
    "FAILED" || "SEND_UNKNOWN" => TaskLabel.error,
    _ =>
      taskGroupOf(workCase) == TaskGroup.running
          ? TaskLabel.running
          : TaskLabel.waiting,
  };
}

/// 보류 사유로 짐작하는 단계(1 요청 확인 · 2 후보 · 3 견적 요청 · 4 회신 · 5 검토).
const _holdStages = {
  "SUPPLIER_NOT_MATCHED": 1,
  "SUPPLIER_MISMATCH": 1,
  "MISSING_FIELD": 1,
  "MISSING_EVIDENCE": 1,
  "SOURCE_READ_FAILED": 1,
  "NO_SUITABLE_CANDIDATES": 2,
  "CONDITIONS_MISSING": 3,
  "SEND_POLICY_REQUIRED": 3,
  "NO_QUOTE_DATA": 4,
  "COUNTER_OFFER_POLICY_MISSING": 5,
  "COUNTER_OFFER_NOT_COMPUTABLE": 5,
};

/// 목록 행의 진행도 n(전체 [CaseStage.total]). 단계를 알 수 없으면
/// (처리 오류, 사유 없는 보류) null이고 칸은 비워 둡니다.
int? taskProgressOf(WorkCase workCase) {
  if (workCase.archived) return CaseStage.total;
  final step = workCase.processingStep;
  switch (step) {
    case "PENDING_START" || "ACKNOWLEDGED":
      return 1;
    case ProcessingStep.needsInfo:
      return 3;
    case ProcessingStep.onHold:
      return _holdStages[workCase.hold?.code];
    case "FAILED":
      return null;
  }
  final blocked = workCase.disabledActions
      .where((disabled) => disabled.action == WorkCaseAction.selectCandidates)
      .firstOrNull;
  return caseStageOf(
    step,
    inputRevision: workCase.inputRevision,
    canSelectCandidates: _userPicksCandidates(workCase),
    // 막힌 이유가 없을 때만 서버가 견적 요청을 준비하는 중입니다.
    preparingRfq: blocked == null,
    rfqSent: workCase.replySummary?.visible ?? true,
  )?.index;
}
