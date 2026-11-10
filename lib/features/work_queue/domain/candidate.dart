import "../../mail_draft/domain/mail_draft.dart";
import "work_case.dart";

/// API-11 후보 세트. 조건 충족 여부는 MET·UNMET·UNKNOWN입니다.
enum CheckState {
  met("MET", "충족"),
  unmet("UNMET", "불충족"),
  unknown("UNKNOWN", "미확인");

  const CheckState(this.code, this.label);
  final String code;
  final String label;

  static CheckState fromCode(String code) => values.firstWhere(
    (state) => state.code == code,
    orElse: () => unknown,
  );
}

/// 필수 조건 또는 선호 조건 한 줄.
class CandidateCheck {
  const CandidateCheck({
    required this.label,
    required this.state,
    this.required = true,
  });

  final String label;
  final CheckState state;
  final bool required;
}

/// 서버가 확인 못 한 항목의 키. 모르는 키는 그대로 보여 줍니다.
const _unknownFieldLabels = {
  "item_name": "품목명",
  "specification": "규격",
  "quantity": "수량",
  "unit": "단위",
  "unit_price": "단가",
  "due_date": "납기",
  "origin": "원산지",
  "certifications": "인증",
  "contact_email": "연락처",
  "supplier_name": "업체명",
};

String unknownFieldLabel(String key) => _unknownFieldLabels[key] ?? key;

class Candidate {
  const Candidate({
    required this.supplierId,
    required this.name,
    required this.handlingEvidence,
    this.reason = "",
    this.contactEmail,
    this.checks = const [],
    this.preferenceScore,
    this.webCandidate = false,
    this.caution,
    this.unknownFields = const [],
  });

  final String supplierId;
  final String name;
  final String? contactEmail;

  /// 이 품목을 취급한다고 본 근거(거래 이력·등록 품목 등).
  final String handlingEvidence;

  /// 에이전트가 이 후보를 고른 이유.
  final String reason;

  /// 주의 사유. 있으면 자동 발송하지 않고 승인을 기다립니다.
  final String? caution;

  /// 이 후보에서 확인하지 못한 항목의 키.
  final List<String> unknownFields;
  final List<CandidateCheck> checks;

  /// 선호 점수(0~100). 필수 조건 위반을 가리지 않습니다.
  final int? preferenceScore;

  /// 웹 탐색 후보: 회신 확인 전이라 기존 거래처로 확정하지 않습니다.
  final bool webCandidate;

  bool get failsRequired =>
      checks.any((check) => check.required && check.state == CheckState.unmet);

  /// 연락처가 없거나 필수 조건을 어기면 견적 요청 대상으로 고를 수 없습니다.
  bool get selectable => contactEmail != null && !failsRequired;
}

class CandidateSet {
  const CandidateSet({
    required this.id,
    required this.revision,
    required this.candidates,
    this.selectedSupplierIds = const [],
    this.isStale = false,
    this.unknownFields = const [],
    this.allowedActions = const [],
    this.disabledActions = const [],
  });

  final String id;
  final int revision;
  final List<Candidate> candidates;

  /// 이미 저장한 선택(다시 열었을 때 체크 상태 복원).
  final List<String> selectedSupplierIds;

  /// 업무 입력이 바뀌어 이 후보는 과거 후보입니다. 고를 수 없습니다.
  final bool isStale;

  /// 업무 전체에서 확인하지 못한 항목의 키.
  final List<String> unknownFields;
  final List<String> allowedActions;
  final List<DisabledWorkCaseAction> disabledActions;

  /// 선택 가능 여부는 서버의 allowed_actions를 따르고, 과거 후보는 막습니다.
  bool get canSelect =>
      !isStale && allowedActions.contains(WorkCaseAction.selectCandidates);

  String? get blockedReason =>
      disabledActions
          .where((disabled) => disabled.action == WorkCaseAction.selectCandidates)
          .firstOrNull
          ?.message ??
      (isStale ? "업무 내용이 바뀌어 이전 후보로는 견적을 요청할 수 없어요." : null);

  /// 서버 사정으로 지금은 후보를 고를 수 없을 때 목록 위에 보일 안내.
  /// 과거 후보(따로 안내)이거나 이미 고른 뒤라면 null입니다.
  String? get serverBlockedNotice {
    if (canSelect || isStale || selectedSupplierIds.isNotEmpty) return null;
    final disabled = disabledActions
        .where((disabled) => disabled.action == WorkCaseAction.selectCandidates)
        .firstOrNull;
    if (disabled == null) return null;
    return switch (disabled.reasonCode) {
      // 서버의 후보 선택·발송 기능이 꺼져 있습니다. 서버 문구는 개발자용이라 바꿔 보여줍니다.
      "CANDIDATE_SELECTION_INTEGRATION_REQUIRED" || "PROCESSING_UNAVAILABLE" =>
        "지금은 견적 요청을 보낼 수 없어요. 서버 준비가 끝나면 다시 고를 수 있어요.",
      _ => disabled.message,
    };
  }
}

/// API-12 drafts[]: the RFQ draft made for one selected supplier.
class SelectedDraft {
  const SelectedDraft({
    required this.draftId,
    required this.supplierId,
    required this.dispatchState,
  });

  final String draftId;
  final String supplierId;

  /// null for a state this app does not know yet.
  final DraftDispatchState? dispatchState;
}
