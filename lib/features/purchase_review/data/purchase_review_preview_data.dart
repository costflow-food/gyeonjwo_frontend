import "dart:convert";

/// Synthetic API-13/14 shapes for the UI preview page and tests only.
/// Supplier names and numbers are invented.
const previewReviewCaseId = "c0a80001-0000-4000-8000-000000000000";

const _a = "s0a80001-0000-4000-8000-00000000000a";
const _b = "s0a80001-0000-4000-8000-00000000000b";
const _c = "s0a80001-0000-4000-8000-00000000000c";
const _qa = "q0a80001-0000-4000-8000-00000000000a";
const _qb = "q0a80001-0000-4000-8000-00000000000b";
const _qc = "q0a80001-0000-4000-8000-00000000000c";
const _mail = "m0a80001-0000-4000-8000-000000000000";

Map<String, dynamic> copyJson(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

/// API-14 data by case. A fresh copy each call so decisions stay per page.
Map<String, Map<String, dynamic>> previewReviewCards() => {
  previewReviewCaseId: copyJson(_strawberryCard),
};

const _strawberryCard = {
  "case_id": previewReviewCaseId,
  "review_revision": 1,
  "input_revision": 2,
  "is_stale": false,
  "created_at": "2026-10-18T03:40:00Z",
  "review_outcome": "OPTIONS_READY",
  "source_quote_ids": [_qa, _qb, _qc],
  "plans": [
    {
      "plan_id": "plan-1-switch",
      "plan_type": "SWITCH",
      "validation_status": "VALID",
      "total_amount": "5400000",
      "currency": "KRW",
      "allocations": [
        {
          "supplier_id": _b,
          "supplier_name": "B사 (합성)",
          "quote_id": _qb,
          "quantity": "1000",
          "unit": "kg",
          "unit_price": "5400",
        },
      ],
      "conditions": [],
      "adjustments": [],
      "reason": "필수 조건을 충족하는 안 중 총액이 가장 낮아요.",
    },
    {
      "plan_id": "plan-1-split",
      "plan_type": "SPLIT",
      "validation_status": "VALID",
      "total_amount": "5560000",
      "currency": "KRW",
      "allocations": [
        {
          "supplier_id": _b,
          "supplier_name": "B사 (합성)",
          "quote_id": _qb,
          "quantity": "600",
          "unit": "kg",
          "unit_price": "5400",
        },
        {
          "supplier_id": _a,
          "supplier_name": "A사 (합성)",
          "quote_id": _qa,
          "quantity": "400",
          "unit": "kg",
          "unit_price": "5800",
        },
      ],
      "conditions": [],
      "adjustments": ["B사 공급 가능량 600kg에 맞춰 나머지를 A사에 배정했어요."],
      "reason": "한 업체에 몰리지 않게 나눠 사는 안이에요.",
    },
    {
      "plan_id": "plan-1-keep",
      "plan_type": "KEEP",
      "validation_status": "CONDITIONAL",
      "total_amount": "5800000",
      "currency": "KRW",
      "allocations": [
        {
          "supplier_id": _a,
          "supplier_name": "A사 (합성)",
          "quote_id": _qa,
          "quantity": "1000",
          "unit": "kg",
          "unit_price": "5800",
        },
      ],
      "conditions": ["역제안 회신에 따라 단가가 바뀔 수 있어요."],
      "adjustments": [],
      "reason": "기존 업체를 유지하는 안이에요.",
    },
  ],
  "counter_offer": {
    "status": "PROPOSED",
    "reason": "대안 총액 이하가 되는 단가로 A사에 역제안할 수 있어요.",
    "target": {
      "supplier_id": _a,
      "supplier_name": "A사 (합성)",
      "target_unit_price": "5400",
      "conditions": ["11월 공급분 1,000kg 기준"],
    },
    "reference": {
      "status": "PROPOSABLE",
      "unit": "kg",
      "requested_unit_price": "5800",
      "previous_unit_price": "5200",
      "ceiling_unit_price": "5400",
      "alternative_total": "5400000",
      "allowed_range": ["5200", "5400"],
    },
    "draft_ids": [],
  },
  "questions": [
    {
      "supplier_id": _c,
      "supplier_name": "C사 (합성)",
      "field": "shipping_cost",
      "priority": "HIGH",
      "reason": "운송비가 메일에 없어 총액을 비교하지 못했어요.",
      "break_even_amount": "100000",
      "formula": "운송비가 100,000원 이하이면 C사 전환안이 B사 전환안보다 싸요.",
    },
  ],
  "unresolved": ["C사는 운송비가 확인되지 않아 구매안에서 뺐어요."],
  "decision": null,
  "allowed_actions": ["SELECT_PLAN", "HOLD", "CONFIRM_REVIEW"],
  "disabled_actions": [],
};

/// API-13 items by case.
const previewReviewQuotes = {
  previewReviewCaseId: [
    {
      "quote_id": _qa,
      "version_no": 2,
      "supplier_id": _a,
      "supplier_name": "A사 (합성)",
      "is_incumbent": true,
      "source_mail_id": _mail,
      "extraction_status": "CONFIRMED",
      "unit_price": "5800",
      "unit": "kg",
      "currency": "KRW",
      "tax_basis": "EXCLUDED",
      "available_quantity": "1000",
      "moq": null,
      "effective_from": "2026-11-01",
      "valid_until": null,
      "costs": [
        {"cost_type": "SHIPPING", "amount": null, "included_in_price": true, "source_text": "운송비 단가에 포함"},
      ],
      "checks": [
        {"field": "specification", "state": "STATED", "value": "IQF 홀 10kg/박스"},
        {"field": "origin", "state": "STATED", "value": "국내산"},
      ],
      "item_notes": [],
      "evidence": [
        {"field": "unit_price", "raw_value": "kg당 5,800원", "mail_id": _mail, "location": "1:page:1"},
        {"field": "effective_from", "raw_value": "2026년 11월 1일 납품분부터", "mail_id": _mail, "location": "body"},
      ],
    },
    {
      "quote_id": _qb,
      "version_no": 1,
      "supplier_id": _b,
      "supplier_name": "B사 (합성)",
      "is_incumbent": false,
      "source_mail_id": "m0a80001-0000-4000-8000-0000000000b1",
      "extraction_status": "CONFIRMED",
      "unit_price": "5400",
      "unit": "kg",
      "currency": "KRW",
      "tax_basis": "EXCLUDED",
      "available_quantity": "1000",
      "moq": {"quantity": "100", "unit": "kg"},
      "effective_from": "2026-11-01",
      "valid_until": "2026-11-30",
      "costs": [
        {"cost_type": "SHIPPING", "amount": null, "included_in_price": true, "source_text": "운송비 포함"},
      ],
      "checks": [
        {"field": "specification", "state": "STATED", "value": "IQF 홀 10kg/박스"},
        {"field": "certifications", "state": "STATED", "value": "HACCP"},
      ],
      "item_notes": ["주문 후 3일 내 출고"],
      "evidence": [
        {"field": "unit_price", "raw_value": "5,400원/kg", "mail_id": "m0a80001-0000-4000-8000-0000000000b1", "location": "body"},
      ],
    },
    {
      "quote_id": _qc,
      "version_no": 1,
      "supplier_id": _c,
      "supplier_name": "C사 (합성)",
      "is_incumbent": false,
      "source_mail_id": "m0a80001-0000-4000-8000-0000000000c1",
      "extraction_status": "CONFIRMED",
      "unit_price": "5300",
      "unit": "kg",
      "currency": "KRW",
      "tax_basis": null,
      "available_quantity": null,
      "moq": null,
      "effective_from": null,
      "valid_until": null,
      "costs": [],
      "checks": [
        {"field": "specification", "state": "STATED", "value": "IQF 홀 10kg/박스"},
        {"field": "shipping_cost", "state": "MISSING", "value": null},
      ],
      "item_notes": [],
      "evidence": [
        {"field": "unit_price", "raw_value": "kg 5,300원", "mail_id": "m0a80001-0000-4000-8000-0000000000c1", "location": "body"},
      ],
    },
  ],
};
