// Mock API-30 `data` payloads. Suppliers, contacts, and prices are synthetic.
// The preview DataSource derives API-29 list rows from these.
const supplierPreviewDetails = [
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a001",
    "name": "A사",
    "business_registration_no": "214-81-00001",
    "contact_email": "sales@a-supplier.example.com",
    "contact": {"name": "김영업", "phone": "02-0000-0001"},
    "location": "경기 이천시",
    "source_type": "REGISTERED",
    "evidence": {
      "source_label": "기존 거래 계약서",
      "checked_at": "2026-10-01T01:00:00Z",
      "memo": "2026 상반기 공급 계약 기준",
    },
    "items": [
      {
        "supplier_item_id": "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e001",
        "item_name": "냉동 딸기",
        "specification": "IQF 홀 / 10kg 박스",
        "unit": "kg",
        "units_per_box": "10",
        "weight_per_box": "10",
        "origin": "국산(충남 논산)",
        "certifications": [
          {"name": "HACCP", "status": "CONFIRMED", "valid_until": "2027-03-31"},
        ],
        "notes": "11월부터 공급단가 조정 예정 안내를 받음",
        "notes_evidence": {
          "source_label": "단가변경 안내 메일",
          "checked_at": "2026-10-19T01:24:00Z",
          "source_mail_id": "REQ-2026-1019-003",
        },
        "latest_reference_quote": {
          "unit_price": "5500",
          "unit": "kg",
          "effective_from": "2026-11-01",
        },
        "last_purchase": {
          "unit_price": "5000",
          "unit": "kg",
          "transaction_date": "2026-10-10",
        },
      },
      {
        "supplier_item_id": "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e002",
        "item_name": "냉동 블루베리",
        "specification": "IQF / 5kg 박스",
        "unit": "kg",
        "units_per_box": "5",
        "weight_per_box": "5",
        "origin": "칠레",
        "certifications": [
          {"name": "HACCP", "status": "CONFIRMED", "valid_until": "2027-03-31"},
          {"name": "유기농", "status": "UNCONFIRMED", "valid_until": null},
        ],
        "notes": null,
        "notes_evidence": null,
        "latest_reference_quote": null,
        "last_purchase": null,
      },
    ],
  },
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a002",
    "name": "B사",
    "business_registration_no": null,
    "contact_email": "order@b-supplier.example.com",
    "contact": {"name": null, "phone": "031-000-0002"},
    "location": "충남 논산시",
    "source_type": "VERIFIED_WEB",
    "evidence": {
      "source_label": "업체 홈페이지 확인 후 등록",
      "checked_at": "2026-10-15T05:30:00Z",
      "memo": null,
    },
    "items": [
      {
        "supplier_item_id": "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e003",
        "item_name": "냉동 딸기",
        "specification": "IQF 슬라이스 / 10kg 박스",
        "unit": "kg",
        "units_per_box": "10",
        "weight_per_box": null,
        "origin": "국산",
        "certifications": [
          {"name": "HACCP", "status": "UNCONFIRMED", "valid_until": null},
        ],
        "notes": "월 600kg 이상 공급은 사전 협의 필요하다고 회신함",
        "notes_evidence": {
          "source_label": "견적 회신 메일",
          "checked_at": "2026-10-20T02:10:00Z",
        },
        "latest_reference_quote": {
          "unit_price": "5400",
          "unit": "kg",
          "effective_from": "2026-10-20",
        },
        "last_purchase": null,
      },
    ],
  },
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a003",
    "name": "C사",
    "business_registration_no": "608-86-00003",
    "contact_email": "biz@c-supplier.example.com",
    "contact": {"name": "박구매", "phone": null},
    "location": "제주 서귀포시",
    "source_type": "REGISTERED",
    "evidence": {
      "source_label": "거래처 등록 신청서",
      "checked_at": "2026-09-12T00:00:00Z",
      "memo": null,
    },
    "items": [
      {
        "supplier_item_id": "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e004",
        "item_name": "한라감귤",
        "specification": "로얄과 / 5kg 박스",
        "unit": "box",
        "units_per_box": "1",
        "weight_per_box": "5",
        "origin": "국산(제주)",
        "certifications": [
          {"name": "GAP", "status": "NOT_MET", "valid_until": "2026-08-31"},
        ],
        "notes": "GAP 인증 갱신 서류 대기 중",
        "notes_evidence": {
          "source_label": "업체 회신 메일",
          "checked_at": "2026-10-02T04:00:00Z",
        },
        "latest_reference_quote": null,
        "last_purchase": {
          "unit_price": "21000",
          "unit": "box",
          "transaction_date": "2026-01-15",
        },
      },
    ],
  },
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a004",
    "name": "D사",
    "business_registration_no": "135-81-00004",
    "contact_email": null,
    "contact": {"name": null, "phone": null},
    "location": null,
    "source_type": "REGISTERED",
    "evidence": null,
    "items": [],
  },
];

// Mock API-31 `data` by supplier_item_id. Mail quotes and receipt-backed
// purchases are separate arrays and never overwrite each other.
const supplierPricePreviewHistory = {
  "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e001": {
    "reference_quotes": [
      {
        "unit_price": "5500",
        "unit": "kg",
        "effective_from": "2026-11-01",
        "conditions": "IQF 홀 10kg 박스 · 월 1,000kg 기준 · 부가세 별도",
        "source_type": "MAIL_QUOTE",
        "source_label": "단가변경 안내 메일",
        "source_mail_id": "REQ-2026-1019-003",
      },
      {
        "unit_price": "5000",
        "unit": "kg",
        "effective_from": "2026-05-01",
        "conditions": "IQF 홀 10kg 박스 · 부가세 별도",
        "source_type": "MAIL_QUOTE",
        "source_label": "상반기 견적 메일",
        "source_mail_id": null,
      },
    ],
    "actual_purchases": [
      {
        "unit_price": "5000",
        "unit": "kg",
        "transaction_date": "2026-10-10",
        "quantity": "800",
        "conditions": "IQF 홀 10kg 박스 80개",
        "source_type": "RECEIPT",
        "source_label": "거래명세서 2026-10-10",
      },
      {
        "unit_price": "5000",
        "unit": "kg",
        "transaction_date": "2026-09-08",
        "quantity": "1000",
        "conditions": "IQF 홀 10kg 박스 100개",
        "source_type": "RECEIPT",
        "source_label": "영수증 2026-09-08",
      },
    ],
  },
  "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e003": {
    "reference_quotes": [
      {
        "unit_price": "5400",
        "unit": "kg",
        "effective_from": "2026-10-20",
        "conditions": "IQF 슬라이스 10kg 박스 · 최대 600kg · 배송비 10,000원",
        "source_type": "MAIL_QUOTE",
        "source_label": "견적 회신 메일",
        "source_mail_id": null,
      },
    ],
    "actual_purchases": [],
  },
  "6a1f0d4e-1b2c-4d3e-8f90-a1b2c3d4e004": {
    "reference_quotes": [],
    "actual_purchases": [
      {
        "unit_price": "21000",
        "unit": "box",
        "transaction_date": "2026-01-15",
        "quantity": "40",
        "conditions": "로얄과 5kg 박스",
        "source_type": "RECEIPT",
        "source_label": "거래명세서 2026-01-15",
      },
    ],
  },
};
