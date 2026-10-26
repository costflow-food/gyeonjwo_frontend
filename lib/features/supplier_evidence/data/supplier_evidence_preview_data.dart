// Mock API responses; the shared figures are synthetic demonstration values.
const _existingSupplierEvidence = {
  "subtitle": "요청·계약 적용·비용 영향",
  "impactCaption": "11월 전체 1,000kg · 운송비와 기타 물류비 포함",
  "monthlyCostImpact": 300000,
  "impactNote": "변경 단가는 전체 물량 중 600kg에만 적용합니다.",
  "costLines": [
    {"label": "기존 전체 구매금액", "value": "1,000kg × 5,000원 = 5,000,000원"},
    {
      "label": "변경 전체 구매금액",
      "value": "400kg × 5,000원 + 600kg × 5,500원\n= 5,300,000원",
    },
    {"label": "월 운송비 · 단가 미포함", "value": "120,000원 · 회사 별도 부담"},
    {"label": "월 기타 물류비 · 단가 미포함", "value": "30,000원 · 회사 별도 부담"},
    {"label": "기존 월 총구매비용", "value": "5,150,000원"},
    {"label": "변경 월 총구매비용", "value": "5,450,000원", "emphasized": true},
  ],
  "crossCheckFormulas": [
    "(5,500 − 5,000) × 600 = 300,000원",
    "5,450,000 − 5,150,000 = 300,000원",
  ],
  "crossCheckNote":
      "부대비용은 변경 전후 동일한 합성 조건입니다. 월 전체 부대비용을 변경 물량 600kg에 임의 배분하지 않았습니다.",
  "disclaimer": "문서의 합성 계산 정답을 표시한 시안입니다. 실제 계산 에이전트의 독립 회차 검증이나 API 분석이 수행된 것은 아닙니다. 세금 조건은 미제공입니다.",
  "sections": [
    {
      "title": "요청 및 계약 적용 근거",
      "body": "요청 메일의 단가변경 문구와 합성 계약·구매계획을 대조한 사례입니다. 11월 1,000kg 중 400kg은 고정단가, 600kg은 변경 검토 물량으로 설정했습니다. 공급 기간·재고·인증은 미확인입니다.",
      "tag": "계약서 · 구매계획 / UX 보완 합성값",
    },
    {
      "title": "과거 구매와 거래 경험",
      "body": "구매이력: 10월 800kg × 5,000원/kg.\n회사 평가 코멘트: “최근 납품에서 포장 상태 양호.”\n두 항목은 UX 보완 합성값이며, 평가 코멘트는 가격 근거와 구분합니다.",
    },
    {
      "title": "직접 비교에서 제외한 자료",
      "body": "생딸기 견적은 가공 상태가 달라 이번 냉동 딸기 단가와 직접 비교하지 않았습니다.",
    },
  ],
};

const _candidateSections = [
  {"title": "과거 구매와 거래 경험", "body": "거래 이력이 없어 구매이력과 회사 평가 코멘트가 없습니다."},
  {
    "title": "직접 비교에서 제외한 자료",
    "body": "생딸기 견적은 가공 상태가 달라 이번 냉동 딸기 단가와 직접 비교하지 않았습니다.",
  },
];

const _candidateImpactNote = "미확인 부대비용과 계약 적용 조건으로 월 전체 총비용을 확정할 수 없습니다.";
const _candidateCrossCheckNote =
    "단가 비교용 차액입니다. 운송비·기타 물류비가 확인되지 않아 실제 절감액으로 보지 않습니다.";
const _candidateDisclaimer = "문서의 합성 계산 정답을 표시한 시안입니다. 견적 유효기간과 세금 조건은 미제공입니다.";

const _supplierBEvidence = {
  "subtitle": "보유 DB 견적·단가 비교",
  "impactCaption": "변경 검토 600kg · 운송비와 기타 물류비 미포함",
  "monthlyCostImpact": null,
  "impactNote": _candidateImpactNote,
  "costLines": [
    {"label": "단가 비교용 구매금액", "value": "600kg × 5,200원 = 3,120,000원"},
    {"label": "요청 단가 기준 구매금액", "value": "600kg × 5,500원 = 3,300,000원"},
    {"label": "최소 주문 수량", "value": "500kg"},
    {"label": "공급 소요기간", "value": "자료상 7일"},
    {"label": "월 운송비", "value": "미확인 · 비용·부담 조건 확인 필요", "unconfirmed": true},
    {"label": "월 기타 물류비", "value": "미확인 · 비용·부담 조건 확인 필요", "unconfirmed": true},
    {"label": "월 전체 총구매비용", "value": "확정 불가", "emphasized": true},
  ],
  "crossCheckFormulas": [
    "(5,500 − 5,200) × 600 = 180,000원",
    "3,300,000 − 3,120,000 = 180,000원",
  ],
  "crossCheckNote": _candidateCrossCheckNote,
  "disclaimer": _candidateDisclaimer,
  "sections": [
    {
      "title": "견적 근거",
      "body":
          "보유 DB에 등록된 합성 견적입니다. 동일 규격(냉동 · 무가당 · 10kg/박스) 기준이며 재고·인증은 미확인입니다.",
      "tag": "보유 DB 견적 / UX 보완 합성값",
    },
    ..._candidateSections,
  ],
};

const _supplierCEvidence = {
  "subtitle": "보유 DB 견적·단가 비교",
  "impactCaption": "변경 검토 600kg · 운송비와 기타 물류비 미포함",
  "monthlyCostImpact": null,
  "impactNote": _candidateImpactNote,
  "costLines": [
    {"label": "단가 비교용 구매금액", "value": "600kg × 5,350원 = 3,210,000원"},
    {"label": "요청 단가 기준 구매금액", "value": "600kg × 5,500원 = 3,300,000원"},
    {"label": "최소 주문 수량", "value": "400kg"},
    {"label": "공급 소요기간", "value": "자료상 10일"},
    {"label": "월 운송비", "value": "미확인 · 비용·부담 조건 확인 필요", "unconfirmed": true},
    {"label": "월 기타 물류비", "value": "미확인 · 비용·부담 조건 확인 필요", "unconfirmed": true},
    {"label": "월 전체 총구매비용", "value": "확정 불가", "emphasized": true},
  ],
  "crossCheckFormulas": [
    "(5,500 − 5,350) × 600 = 90,000원",
    "3,300,000 − 3,210,000 = 90,000원",
  ],
  "crossCheckNote": _candidateCrossCheckNote,
  "disclaimer": _candidateDisclaimer,
  "sections": [
    {
      "title": "견적 근거",
      "body":
          "보유 DB에 등록된 합성 견적입니다. 동일 규격(냉동 · 무가당 · 10kg/박스) 기준이며 재고·인증은 미확인입니다.",
      "tag": "보유 DB 견적 / UX 보완 합성값",
    },
    ..._candidateSections,
  ],
};

const _sampleEvidence = {
  "A": _existingSupplierEvidence,
  "B": _supplierBEvidence,
  "C": _supplierCEvidence,
};

// 요청 ID → 거래처 문자 → 상세 근거 응답
const supplierEvidencePreviewResponses = {
  "REQ-2026-1019-003": _sampleEvidence,
  "REQ-2026-1019-002": {
    "D": _existingSupplierEvidence,
    "B": _supplierBEvidence,
    "C": _supplierCEvidence,
  },
  "REQ-2026-1019-001": _sampleEvidence,
  "REQ-2026-1018-002": _sampleEvidence,
};
