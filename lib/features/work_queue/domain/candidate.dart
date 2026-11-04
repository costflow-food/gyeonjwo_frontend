import "../../mail_draft/domain/mail_draft.dart";

/// API-11 후보 세트. 08의 응답 형식은 아직 서버에 없어서 제안 계약을 따릅니다.
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

class Candidate {
  const Candidate({
    required this.supplierId,
    required this.name,
    required this.handlingEvidence,
    this.contactEmail,
    this.checks = const [],
    this.preferenceScore,
    this.webCandidate = false,
  });

  final String supplierId;
  final String name;
  final String? contactEmail;

  /// 이 품목을 취급한다고 본 근거(거래 이력·등록 품목 등).
  final String handlingEvidence;
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
  });

  final String id;
  final int revision;
  final List<Candidate> candidates;

  /// 이미 저장한 선택(다시 열었을 때 체크 상태 복원).
  final List<String> selectedSupplierIds;
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
