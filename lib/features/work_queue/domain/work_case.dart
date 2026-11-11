/// API-01 업무 큐 상태.
enum WorkCaseStatus {
  waiting("Waiting", "대기"),
  running("Running", "진행 중"),
  complete("Complete", "완료"),

  /// 에이전트가 보류(ON_HOLD)한 업무. 서버가 Pending으로 저장합니다.
  pending("Pending", "보류"),
  confirm("Confirm", "확인 필요"),

  /// 그 밖에 아직 모르는 서버 상태.
  other("", "기타");

  const WorkCaseStatus(this.code, this.label);
  final String code;
  final String label;

  static WorkCaseStatus fromCode(String code) => values.firstWhere(
    (status) => status != other && status.code == code,
    orElse: () => other,
  );

  /// 큐 탭에 표시하는 세 상태.
  static const tabs = [waiting, running, complete];

  /// 이 상태의 업무가 들어가는 큐 탭. 보류·실패·승인 대기(Pending)는
  /// 08의 Running/ON_HOLD처럼 진행 중에, 메일만 확인한 업무(Confirm)는
  /// 아직 검토 전이라 대기에 넣습니다. 모르는 상태는 전체에만 보입니다.
  WorkCaseStatus? get tab => switch (this) {
    waiting || confirm => waiting,
    running || pending => running,
    complete => complete,
    other => null,
  };
}

/// API 행동 코드(08 §3). 버튼 표시 여부는 서버의 allowed_actions를 따릅니다.
abstract final class WorkCaseAction {
  static const viewOriginal = "VIEW_ORIGINAL";
  static const start = "START";
  static const acceptIncrease = "ACCEPT_INCREASE";
  static const selectCandidates = "SELECT_CANDIDATES";

  /// API-07. 보류·처리 오류·검토 완료 업무에서 열리며, 사유는 [ResumeReason]입니다.
  static const resume = "RESUME";
}

/// API-07 재개 사유. 단계마다 서버가 받는 사유가 다릅니다.
enum ResumeReason {
  resumeHold("RESUME_HOLD", "다시 추출", "보류 사유를 확인했다면 요청 정보 확인부터 다시 실행해요."),
  retryFailed("RETRY_FAILED", "다시 시도", "오류가 난 처리를 다시 실행해요."),
  reopenReview("REOPEN_REVIEW", "다시 검토", "이 업무의 검토를 다시 실행해요.");

  const ResumeReason(this.code, this.buttonLabel, this.help);
  final String code;
  final String buttonLabel;
  final String help;

  static ResumeReason forStep(String processingStep) =>
      switch (processingStep) {
        "FAILED" => retryFailed,
        "REVIEW_READY" => reopenReview,
        _ => resumeHold,
      };
}

/// 서버 processing_step 중 화면이 따로 다루는 값.
abstract final class ProcessingStep {
  static const onHold = "ON_HOLD";
  static const needsInfo = "NEEDS_INFO";
  static const selectingCandidates = "SELECTING_CANDIDATES";
  static const candidates = "CANDIDATES";

  /// 견적 요청 초안이 만들어진 뒤의 단계. 메일 초안 화면을 열 수 있습니다.
  static const withDrafts = {
    "WAITING_APPROVAL",
    "AWAITING_APPROVAL",
    "WAITING_REPLY",
    "SEND_UNKNOWN",
  };
}

/// API-01 step_detail 문구와 같은 표. API-02·03은 단계 코드만 줍니다.
const _stepLabels = {
  "PENDING_START": "원문 확인 후 검토 시작",
  "ACKNOWLEDGED": "수신 메일 확인됨",
  "EXTRACTING": "요청 정보 확인 중",
  "WAITING_REPLY": "거래처 회신 대기",
  "WAITING_APPROVAL": "발송 승인 대기",
  "AWAITING_APPROVAL": "발송 승인 대기",
  "REVIEW_READY": "검토 결과 준비 완료",
  "FAILED": "처리 오류 확인 필요",
  "ON_HOLD": "검토 보류",
  "NEEDS_INFO": "추가 정보 확인 필요",
  "SELECTING_CANDIDATES": "후보 찾기 대기",
  "CANDIDATES": "견적 요청 준비 중",
  "GENERATING_PLANS": "검토안 생성 중",
  "BUILDING_PLANS": "검토안 생성 중",
  "BUILDING_COUNTER_OFFER": "역제안 준비 중",
  "SEND_UNKNOWN": "발송 결과 확인 필요",
};

/// EXTRACTING이지만 처음 추출이 아니라 연결된 거래처 회신을 읽는 중인지.
/// 회신이 연결될 때만 input_revision이 오르므로 1보다 크면 회신 처리입니다.
bool isReplyExtraction(String step, int inputRevision) =>
    step == "EXTRACTING" && inputRevision > 1;

String processingStepLabel(String step, {int inputRevision = 1}) =>
    isReplyExtraction(step, inputRevision)
    ? "거래처 회신 확인 중"
    : _stepLabels[step] ?? "처리 상태 확인";

/// 서버 hold 문구가 없을 때 error.code로 고르는 대체 문구.
const _fallbackStopMessages = {
  "NO_SUITABLE_CANDIDATES": "요청 조건에 맞는 거래처 후보를 찾지 못했어요.",
  "SEND_POLICY_REQUIRED": "견적 요청에 필요한 발송 설정을 확인해야 해요.",
};

/// 거래처가 없어 멈춘 코드. 거래처 등록으로 원인을 풀 수 있습니다.
const supplierMissingStopCodes = {
  "NO_SUITABLE_CANDIDATES",
  "NO_REGISTERED_SUPPLIER_EVIDENCE",
};

/// 멈춘 이유 문구. 서버 hold 문구가 우선이고, 없으면 [errorCode]의 임시 문구입니다.
String? stopReasonMessage(HoldReason? hold, String? errorCode) =>
    hold?.message ?? _fallbackStopMessages[errorCode];

/// API-01·03 hold. 문구는 서버가 정한 그대로 보여 줍니다.
class HoldReason {
  const HoldReason({required this.code, required this.message});

  final String code;
  final String message;
}

/// API-03 저장된 진행 단계. 검토 진행 팝업과 보류 안내가 함께 씁니다.
class CaseProgress {
  const CaseProgress({
    required this.caseId,
    required this.status,
    required this.processingStep,
    required this.inputRevision,
    this.hold,
    this.errorCode,
  });

  /// API-03 `data`.
  factory CaseProgress.fromJson(Map<String, dynamic> json) {
    final hold = json["hold"];
    final error = json["error"];
    return CaseProgress(
      caseId: json["case_id"] as String,
      status: json["status"] as String,
      processingStep: json["processing_step"] as String,
      inputRevision: json["input_revision"] as int,
      hold: hold is Map<String, dynamic>
          ? HoldReason(
              code: hold["code"] as String,
              message: hold["message"] as String,
            )
          : null,
      errorCode: error is Map<String, dynamic>
          ? error["code"] as String?
          : null,
    );
  }

  final String caseId;
  final String status;
  final String processingStep;
  final int inputRevision;
  final HoldReason? hold;

  /// error.code. 화면 문구로 쓰지 않습니다.
  final String? errorCode;

  /// 멈춘 이유 코드. 단계 추정·버튼 표시에만 쓰고 문구는 [hold]의 message를 씁니다.
  String? get stopCode => hold?.code ?? errorCode;
}

/// API-01 reply_summary. 메일 수가 아니라 이번 차수에 견적 요청을 보낸 업체 수와
/// 그중 회신이 확인된 업체 수입니다.
class ReplySummary {
  const ReplySummary({required this.requested, required this.responded});

  final int requested;
  final int responded;

  /// 견적 요청을 보낸 업체가 있을 때만 표시합니다.
  bool get visible => requested > 0;

  /// 예: "회신 2/8곳".
  String get shortLabel => "회신 $responded/$requested곳";

  /// 예: "견적 요청 8곳 중 2곳 회신 (25%)".
  String get label =>
      "견적 요청 $requested곳 중 $responded곳 회신 "
      "(${(responded * 100 / requested).round()}%)";
}

class DisabledWorkCaseAction {
  const DisabledWorkCaseAction({
    required this.action,
    required this.reasonCode,
    required this.message,
  });

  final String action;
  final String reasonCode;
  final String message;
}

/// API-01의 업무 한 건. 메일 본문은 담지 않습니다(원문은 API-25).
class WorkCase {
  const WorkCase({
    required this.id,
    required this.initialMailId,
    required this.title,
    required this.sender,
    required this.receivedAt,
    required this.status,
    required this.statusCode,
    required this.processingStep,
    required this.stepMessage,
    required this.inputRevision,
    required this.attachmentCount,
    this.senderName,
    this.itemName,
    this.hold,
    this.replySummary,
    this.allowedActions = const [],
    this.disabledActions = const [],
  });

  final String id;
  final String initialMailId;
  final String title;
  final String sender;
  final String? senderName;

  /// 품목. 검토 전(추출 전)에는 null일 수 있습니다.
  final String? itemName;

  /// UTC ISO 8601. 화면은 Asia/Seoul로 표시합니다.
  final String receivedAt;
  final WorkCaseStatus status;

  /// 서버가 보낸 원래 상태 값(기타 상태 표시용).
  final String statusCode;
  final String processingStep;

  /// API-01 step_detail.message.
  final String stepMessage;
  final int inputRevision;
  final int attachmentCount;

  /// ON_HOLD일 때 서버가 정한 보류 사유.
  final HoldReason? hold;

  /// 회신 현황. API-01에만 있고 API-02로 읽은 업무는 null입니다.
  final ReplySummary? replySummary;
  final List<String> allowedActions;
  final List<DisabledWorkCaseAction> disabledActions;

  /// 아직 검토를 실행하지 않은 업무. 원문 확인 후 수긍·대안 찾기를 고릅니다.
  bool get notStarted => status == WorkCaseStatus.waiting;

  /// 저장된 검토 카드가 있는 업무(API-14). 카드 화면으로 갈 수 있습니다.
  bool get hasReviewCard =>
      processingStep == "REVIEW_READY" || status == WorkCaseStatus.complete;

  bool get onHold => processingStep == ProcessingStep.onHold;

  /// 후보 단계(후보 찾기 대기·견적 요청 준비).
  bool get atCandidates =>
      processingStep == ProcessingStep.selectingCandidates ||
      processingStep == ProcessingStep.candidates;

  /// 멈춘 이유를 API-03에서 다시 확인할 단계.
  bool get stopped => onHold || processingStep == ProcessingStep.needsInfo;

  /// 이 업무에서 재개할 때 보낼 사유.
  ResumeReason get resumeReason => ResumeReason.forStep(processingStep);

  bool can(String action) => allowedActions.contains(action);

  String? disabledMessage(String action) => disabledActions
      .where((disabled) => disabled.action == action)
      .firstOrNull
      ?.message;
}

/// 사이드바의 품목 그룹. [itemName]이 null이면 품목 미확인 묶음입니다.
class WorkCaseGroup {
  const WorkCaseGroup({required this.itemName, required this.cases});

  final String? itemName;

  /// 최신 수신순.
  final List<WorkCase> cases;

  String get label => itemName == null ? "품목 미확인" : "$itemName 품목";

  int get waitingCount => cases.where((workCase) => workCase.notStarted).length;
}

class WorkQueueCounts {
  const WorkQueueCounts({
    this.waiting = 0,
    this.running = 0,
    this.complete = 0,
    this.total = 0,
  });

  /// 받아 둔 업무로 탭 건수를 셉니다. 탭은 [WorkCaseStatus.tab]을 따릅니다.
  factory WorkQueueCounts.fromCases(List<WorkCase> cases) {
    int count(WorkCaseStatus tab) =>
        cases.where((workCase) => workCase.status.tab == tab).length;
    return WorkQueueCounts(
      waiting: count(WorkCaseStatus.waiting),
      running: count(WorkCaseStatus.running),
      complete: count(WorkCaseStatus.complete),
      total: cases.length,
    );
  }

  final int waiting;
  final int running;
  final int complete;
  final int total;

  /// null은 전체 탭입니다.
  int countFor(WorkCaseStatus? status) => switch (status) {
    null ||
    WorkCaseStatus.pending ||
    WorkCaseStatus.confirm ||
    WorkCaseStatus.other => total,
    WorkCaseStatus.waiting => waiting,
    WorkCaseStatus.running => running,
    WorkCaseStatus.complete => complete,
  };
}

class WorkQueuePage {
  const WorkQueuePage({
    required this.items,
    required this.counts,
    this.nextCursor,
  });

  final List<WorkCase> items;
  final WorkQueueCounts counts;
  final String? nextCursor;
}

class MailAttachment {
  const MailAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String id;
  final String filename;
  final String mimeType;
  final int sizeBytes;

  bool get isPdf =>
      mimeType == "application/pdf" || filename.toLowerCase().endsWith(".pdf");
}

/// API-25 원문. 추출·OCR 결과가 아닌 저장된 메일 그대로입니다.
class OriginalMail {
  const OriginalMail({
    required this.id,
    required this.subject,
    required this.sender,
    required this.recipients,
    required this.receivedAt,
    required this.bodyText,
    this.attachments = const [],
  });

  final String id;
  final String subject;
  final String sender;
  final List<String> recipients;
  final String receivedAt;
  final String bodyText;
  final List<MailAttachment> attachments;
}

/// 08 오류 응답의 code·message.
class WorkQueueFailure implements Exception {
  const WorkQueueFailure(
    this.code,
    this.message, {
    this.unknownOutcome = false,
  });

  final String code;
  final String message;

  /// 응답을 받지 못해 서버 처리 여부를 알 수 없음. 같은 요청으로 다시 확인합니다.
  final bool unknownOutcome;

  /// 다른 화면·사용자가 업무를 바꿨으니 목록을 다시 불러와야 합니다.
  bool get caseChanged => const {
    "REVISION_CONFLICT",
    "WORK_ALREADY_STARTED",
    "ACTION_NOT_ALLOWED",
    "RESOURCE_NOT_FOUND",
    "CANDIDATES_CHANGED",
  }.contains(code);

  /// 후보 세트가 바뀌었거나 이 선택이 더 맞지 않음: 후보를 다시 조회합니다.
  bool get candidatesChanged => const {
    "CANDIDATES_CHANGED",
    "REVISION_CONFLICT",
    "ACTION_NOT_ALLOWED",
    "CANDIDATES_NOT_READY",
    "INVALID_CANDIDATE_SELECTION",
  }.contains(code);

  @override
  String toString() => "WorkQueueFailure($code)";
}
