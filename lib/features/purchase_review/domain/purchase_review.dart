/// API-14 검토 카드와 API-13 견적. 저장된 카드(work_cases.latest_review_jsonb)를
/// 보여 줍니다. 안별 합계는 서버 값이고, 최저가 표시·최저가 대비 차액·배정 비율은
/// 화면(plan_board.dart)에서 계산합니다.
library;

/// 서버의 행동 코드. API-14 allowed_actions·disabled_actions와 API-15 decision에 씁니다.
abstract final class ReviewAction {
  static const selectPlan = "SELECT_PLAN";
  static const hold = "HOLD";
  static const confirmReview = "CONFIRM_REVIEW";
}

/// 검토가 끝난 결과. 정상 비교 성공과 그렇지 않은 종료를 구분합니다.
///
/// 08은 OPTIONS_READY·NEEDS_INFO·ON_HOLD를, 현재 BE·DB(06 종료 코드)는
/// COMPLETED·NO_VALID_PLAN·REVIEW_REQUIRED_CLOSED를 보냅니다. 코드 집합이
/// 합의될 때까지 두 집합을 모두 받아 같은 뜻으로 보여 줍니다.
enum ReviewOutcome {
  optionsReady("OPTIONS_READY", "비교가 끝났습니다. 구매안을 골라 주세요."),
  completed("COMPLETED", "비교가 끝났습니다. 구매안을 골라 주세요."),
  noFeasiblePlan("NO_FEASIBLE_PLAN", "요청 조건을 만족하는 구매안이 없습니다."),
  noValidPlan("NO_VALID_PLAN", "요청 조건을 만족하는 구매안이 없습니다."),
  needsInfo("NEEDS_INFO", "확인이 필요한 항목이 있어 비교를 끝내지 못했습니다."),
  reviewRequiredClosed("REVIEW_REQUIRED_CLOSED", "확인이 필요한 항목이 남은 채 검토를 마쳤습니다."),
  onHold("ON_HOLD", "검토를 보류했습니다."),
  unknown("", "업무에서 현재 상태를 확인해 주세요.");

  const ReviewOutcome(this.code, this.message);
  final String code;
  final String message;

  static ReviewOutcome from(String? code) => values.firstWhere(
    (outcome) => outcome.code == code && outcome != unknown,
    orElse: () => unknown,
  );

  bool get ready => this == optionsReady || this == completed;
}

class DisabledReviewAction {
  const DisabledReviewAction({
    required this.action,
    required this.reasonCode,
    required this.message,
  });

  final String action;
  final String reasonCode;
  final String message;
}

const _planTypes = {"KEEP": "기존 업체 유지", "SWITCH": "전량 전환", "SPLIT": "분산 구매"};
const _validation = {
  "VALID": "확정 가능",
  "CONDITIONAL": "조건부",
  "INVALID": "선택 불가",
  "NEEDS_INFO": "확인 필요",
};

/// ④ 구매안. 배정량·총액·검증은 서버가 검증한 값입니다.
class ResponsePlan {
  const ResponsePlan({
    required this.planId,
    required this.planType,
    required this.validationStatus,
    required this.allocations,
    this.totalAmount,
    this.currency = "KRW",
    this.conditions = const [],
    this.adjustments = const [],
    this.reason,
  });

  /// 확정 선택(API-15 SELECT_PLAN)에 보내는 ID. 아직 에이전트 출력에 없을 수
  /// 있으며, 없으면 이 안만 선택할 수 없고 카드는 그대로 보여 줍니다.
  final String? planId;
  final String planType;
  final String validationStatus;
  final List<PlanAllocation> allocations;

  /// 서버 Decimal 문자열. 미확인이면 null.
  final String? totalAmount;
  final String currency;
  final List<String> conditions;
  final List<String> adjustments;
  final String? reason;

  String get typeLabel => _planTypes[planType] ?? planType;
  String get validationLabel =>
      _validation[validationStatus] ?? validationStatus;

  /// 08: 최신 revision의 VALID 안만 확정 선택할 수 있습니다.
  bool get valid => validationStatus == "VALID";

  /// 확정 선택을 보낼 수 있는 안: VALID이고 plan_id가 있음.
  bool get selectable => valid && planId != null;
}

class PlanAllocation {
  const PlanAllocation({
    required this.supplierId,
    required this.supplierName,
    required this.quoteId,
    required this.quantity,
    this.unit,
    this.unitPrice,
  });

  final String supplierId;
  final String supplierName;

  /// 08 quote_id. 에이전트 출력의 quote_version_id도 받습니다. 표시에는 쓰지 않습니다.
  final String? quoteId;
  final String quantity;
  final String? unit;
  final String? unitPrice;
}

const _counterStatus = {
  "PROPOSED": "역제안 제안",
  "SKIPPED": "역제안 생략",
  "HOLD": "역제안 보류",
};

/// ⑤ 역제안 결과. 생략·보류에도 사유와 참고 계산을 보여 줍니다.
class CounterOffer {
  const CounterOffer({
    required this.status,
    this.reason,
    this.target,
    this.reference,
    this.draftIds = const [],
  });

  final String status;
  final String? reason;
  final CounterOfferTarget? target;
  final CounterOfferReference? reference;
  final List<String> draftIds;

  String get statusLabel => _counterStatus[status] ?? status;
}

class CounterOfferTarget {
  const CounterOfferTarget({
    required this.supplierId,
    required this.supplierName,
    required this.targetUnitPrice,
    this.conditions = const [],
  });

  final String supplierId;
  final String supplierName;
  final String targetUnitPrice;
  final List<String> conditions;
}

class CounterOfferReference {
  const CounterOfferReference({
    required this.status,
    this.unit,
    this.requestedUnitPrice,
    this.previousUnitPrice,
    this.ceilingUnitPrice,
    this.alternativeTotal,
    this.allowedRange = const [],
  });

  final String status;
  final String? unit;
  final String? requestedUnitPrice;
  final String? previousUnitPrice;
  final String? ceilingUnitPrice;
  final String? alternativeTotal;
  final List<String> allowedRange;
}

/// ③이 남긴 확인 항목.
class ReviewQuestion {
  const ReviewQuestion({
    required this.supplierName,
    required this.field,
    required this.priority,
    required this.reason,
    this.breakEvenAmount,
    this.formula,
  });

  final String supplierName;
  final String field;
  final String priority;
  final String reason;
  final String? breakEvenAmount;
  final String? formula;

  String get fieldLabel => quoteFieldLabel(field);
}

/// 저장된 판단(API-15). 없으면 아직 판단 전입니다.
class ReviewDecision {
  const ReviewDecision({
    required this.decision,
    this.planId,
    this.note,
    this.decidedAt,
  });

  final String decision;
  final String? planId;
  final String? note;
  final String? decidedAt;
}

/// API-14 저장 카드 한 개.
class ReviewCard {
  const ReviewCard({
    required this.caseId,
    required this.reviewRevision,
    required this.inputRevision,
    required this.isStale,
    required this.outcome,
    required this.plans,
    this.counterOffer,
    this.questions = const [],
    this.unresolved = const [],
    this.sourceQuoteIds = const [],
    this.decision,
    this.createdAt,
    this.allowedActions = const [],
    this.disabledActions = const [],
  });

  final String caseId;
  final int reviewRevision;
  final int inputRevision;

  /// 새 견적·조건으로 입력이 바뀌어 이 카드는 이력입니다. 선택·확인할 수 없습니다.
  final bool isStale;
  final ReviewOutcome outcome;
  final List<ResponsePlan> plans;
  final CounterOffer? counterOffer;
  final List<ReviewQuestion> questions;
  final List<String> unresolved;
  final List<String> sourceQuoteIds;
  final ReviewDecision? decision;
  final String? createdAt;
  final List<String> allowedActions;
  final List<DisabledReviewAction> disabledActions;

  bool can(String action) => !isStale && allowedActions.contains(action);

  String? disabledMessage(String action) => disabledActions
      .where((disabled) => disabled.action == action)
      .firstOrNull
      ?.message;

  ResponsePlan? plan(String? planId) => planId == null
      ? null
      : plans.where((plan) => plan.planId == planId).firstOrNull;
}

/// API-13 견적 한 버전. 원문에서 읽은 값과 필드별 근거를 함께 담습니다.
class QuoteVersion {
  const QuoteVersion({
    required this.quoteId,
    required this.versionNo,
    required this.supplierId,
    required this.supplierName,
    required this.isIncumbent,
    required this.extractionStatus,
    this.unitPrice,
    this.unit,
    this.currency = "KRW",
    this.taxBasis,
    this.availableQuantity,
    this.moq,
    this.effectiveFrom,
    this.validUntil,
    this.costs = const [],
    this.checks = const [],
    this.itemNotes = const [],
    this.evidence = const [],
  });

  final String quoteId;
  final int versionNo;
  final String supplierId;
  final String supplierName;

  /// 이번 업무의 기존 거래처(단가 변경을 요청한 업체).
  final bool isIncumbent;
  final String extractionStatus;
  final String? unitPrice;
  final String? unit;
  final String currency;
  final String? taxBasis;
  final String? availableQuantity;

  /// "100 kg"처럼 수량과 단위를 합친 표시. 미확인이면 null.
  final String? moq;
  final String? effectiveFrom;
  final String? validUntil;
  final List<QuoteCost> costs;
  final List<QuoteCheck> checks;
  final List<String> itemNotes;
  final List<QuoteEvidence> evidence;
}

class QuoteCost {
  const QuoteCost({
    required this.costType,
    this.amount,
    this.includedInPrice,
    this.sourceText,
  });

  final String costType;
  final String? amount;
  final bool? includedInPrice;
  final String? sourceText;

  String get label => _costTypes[costType] ?? costType;
}

class QuoteCheck {
  const QuoteCheck({required this.field, required this.state, this.value});

  final String field;
  final String state;
  final String? value;

  String get label => quoteFieldLabel(field);
}

/// 필드 값이 원문 어디에 적혀 있었는지.
class QuoteEvidence {
  const QuoteEvidence({
    required this.field,
    required this.mailId,
    this.rawValue,
    this.location,
  });

  final String field;
  final String mailId;
  final String? rawValue;
  final String? location;

  String get label => quoteFieldLabel(field);

  /// "body" → 본문, "1:page:2" → 첨부 1 · 2쪽.
  String get locationLabel {
    final value = location;
    if (value == null || value.isEmpty) return "원문";
    if (value == "body") return "본문";
    final page = RegExp(r"^(\d+):page:(\d+)$").firstMatch(value);
    if (page != null) return "첨부 ${page[1]} · ${page[2]}쪽";
    return value;
  }
}

const _costTypes = {
  "SHIPPING": "운송비",
  "LOGISTICS": "물류비",
  "PACKAGING": "포장비",
  "HANDLING": "취급비",
  "OTHER": "기타 비용",
};

const _fieldLabels = {
  "item_name": "품목",
  "specification": "규격",
  "origin": "원산지",
  "certifications": "인증",
  "unit_price": "단가",
  "unit": "단위",
  "tax_terms": "부가세",
  "tax_basis": "부가세",
  "effective_from": "적용일",
  "valid_until": "유효기간",
  "available_quantity": "공급 가능량",
  "moq_quantity": "최소 주문 수량",
  "shipping_cost": "운송비",
  "delivery_date": "납품일",
  "supplier_name": "업체명",
};

String quoteFieldLabel(String field) => _fieldLabels[field] ?? field;

/// 화면 한 장: 저장 카드와 그 근거 견적.
class PurchaseReview {
  const PurchaseReview({required this.card, required this.quotes});

  final ReviewCard card;
  final List<QuoteVersion> quotes;

  /// 카드가 근거로 쓴 견적. 카드에 목록이 없으면 받은 견적 전체.
  List<QuoteVersion> get sourceQuotes => card.sourceQuoteIds.isEmpty
      ? quotes
      : [
          for (final quote in quotes)
            if (card.sourceQuoteIds.contains(quote.quoteId)) quote,
        ];
}

/// API-13·14·15 실패. 서버가 보낸 문구를 그대로 씁니다.
class PurchaseReviewFailure implements Exception {
  const PurchaseReviewFailure(
    this.code,
    this.message, {
    this.unknownOutcome = false,
    this.retryable = false,
  });

  final String code;
  final String message;

  /// 응답을 받지 못해 서버 처리 여부를 알 수 없음. 같은 요청으로 다시 확인합니다.
  final bool unknownOutcome;

  /// 응답 없음·5xx·`retryable: true`: 서버가 처리했을 수 있어 같은 멱등 키를
  /// 남기고 상태를 다시 읽습니다. [unknownOutcome]이면 늘 참입니다.
  final bool retryable;

  /// 아직 카드가 없음(404 REVIEW_NOT_READY). 오류가 아니라 대기 상태입니다.
  bool get notReady => code == "REVIEW_NOT_READY";

  /// 새 견적·조건이나 다른 판단으로 카드가 바뀜. 최신 카드를 다시 읽습니다.
  bool get cardChanged => const {
    "REVISION_CONFLICT",
    "ACTION_NOT_ALLOWED",
    "INVALID_PLAN_SELECTION",
  }.contains(code);

  @override
  String toString() => "PurchaseReviewFailure($code)";
}
