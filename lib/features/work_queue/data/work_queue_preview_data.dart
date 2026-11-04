// API-01·25 형식의 합성 응답. UI 미리보기 페이지와 테스트의 DataSource만 읽습니다.
const workQueuePreviewCases = [
  {
    "case_id": "c0a80001-0000-4000-8000-000000000007",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000007",
    "item_name": "냉동 딸기",
    "title": "[수량변경] 냉동 딸기 IQF 홀 주문 수량 정정",
    "sender": "sales@a-supplier.example.com",
    "sender_name": "A사 영업담당",
    "received_at": "2026-10-19T02:20:00Z",
    "status": "Running",
    "processing_step": "CANDIDATES",
    "step_detail": {"code": "CANDIDATES", "message": "견적 요청 준비 중"},
    "input_revision": 2,
    "attachment_count": 0,
    "allowed_actions": ["VIEW_ORIGINAL"],
    "disabled_actions": [
      {
        "action": "SELECT_CANDIDATES",
        "reason_code": "REVISION_CONFLICT",
        "message": "입력이 바뀌어 후보를 다시 확인해야 합니다.",
      },
    ],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000006",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000006",
    "item_name": "깐마늘",
    "title": "[견적 요청] 깐마늘 공급 단가 문의",
    "sender": "buy@e-mart.example",
    "sender_name": "E사 구매담당",
    "received_at": "2026-10-19T03:05:00Z",
    "status": "Pending",
    "processing_step": "ON_HOLD",
    "step_detail": {"code": "ON_HOLD", "message": "검토 보류"},
    "hold": {
      "code": "MISSING_FIELD",
      "message": "요청 수량이 확인되지 않아 검토를 보류했어요.",
    },
    "input_revision": 1,
    "attachment_count": 0,
    "allowed_actions": ["VIEW_ORIGINAL", "RESUME"],
    "disabled_actions": [],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000005",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000005",
    "item_name": "깐마늘",
    "title": "[단가변경] 깐마늘 1kg 공급 단가 조정",
    "sender": "sales@f-farm.example",
    "sender_name": null,
    "received_at": "2026-10-19T02:40:00Z",
    "status": "Running",
    "processing_step": "NEEDS_INFO",
    "step_detail": {"code": "NEEDS_INFO", "message": "추가 정보 확인 필요"},
    "error": {"code": "NO_SUITABLE_CANDIDATES"},
    "input_revision": 1,
    "attachment_count": 0,
    "allowed_actions": ["VIEW_ORIGINAL"],
    "disabled_actions": [],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000004",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000004",
    "item_name": "냉동 딸기",
    "title": "[단가인상] 냉동 딸기 IQF 홀 10kg 단가 조정",
    "sender": "sales@a-supplier.example.com",
    "sender_name": "A사 영업담당",
    "received_at": "2026-10-19T02:10:00Z",
    "status": "Running",
    "processing_step": "CANDIDATES",
    "step_detail": {"code": "CANDIDATES", "message": "견적 요청 준비 중"},
    "input_revision": 1,
    "attachment_count": 0,
    "allowed_actions": ["VIEW_ORIGINAL", "SELECT_CANDIDATES"],
    "disabled_actions": [],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000003",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000003",
    "item_name": "제주감귤",
    "title": "[단가변경] 11월 제주감귤 공급단가 조정 안내",
    "sender": "sales@a-farm.example",
    "sender_name": "A사 영업담당",
    "received_at": "2026-10-19T01:24:00Z",
    "status": "Waiting",
    "processing_step": "PENDING_START",
    "step_detail": {"code": "PENDING_START", "message": "원문 확인 후 검토 시작"},
    "input_revision": 1,
    "attachment_count": 1,
    "allowed_actions": ["VIEW_ORIGINAL", "START", "ACCEPT_INCREASE"],
    "disabled_actions": [],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000002",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000002",
    "item_name": "제주감귤",
    "title": "[단가변경] 제주감귤 견적 단가 확인 요청",
    "sender": "order@d-food.example",
    "sender_name": null,
    "received_at": "2026-10-19T00:48:00Z",
    "status": "Waiting",
    "processing_step": "PENDING_START",
    "step_detail": {"code": "PENDING_START", "message": "원문 확인 후 검토 시작"},
    "input_revision": 1,
    "attachment_count": 0,
    "allowed_actions": ["VIEW_ORIGINAL", "START", "ACCEPT_INCREASE"],
    "disabled_actions": [],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000001",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000001",
    "item_name": "냉동 딸기",
    "title": "[단가변경] 냉동 딸기 공급 조건 변경의 건",
    "sender": "biz@d-food.example",
    "sender_name": null,
    "received_at": "2026-10-18T07:30:00Z",
    "status": "Running",
    "processing_step": "EXTRACTING",
    "step_detail": {"code": "EXTRACTING", "message": "요청 정보 추출 중"},
    "input_revision": 1,
    "attachment_count": 1,
    "allowed_actions": ["VIEW_ORIGINAL"],
    "disabled_actions": [],
  },
  {
    "case_id": "c0a80001-0000-4000-8000-000000000000",
    "initial_mail_id": "m0a80001-0000-4000-8000-000000000000",
    "item_name": "냉동 딸기",
    "title": "[검토 완료] 냉동 딸기 단가 조정 안내",
    "sender": "sales@a-farm.example",
    "sender_name": "A사 영업담당",
    "received_at": "2026-10-18T00:12:00Z",
    "status": "Complete",
    "processing_step": "REVIEW_READY",
    "step_detail": {"code": "REVIEW_READY", "message": "최신 검토 카드 준비됨"},
    "input_revision": 2,
    "attachment_count": 2,
    "allowed_actions": ["VIEW_ORIGINAL"],
    "disabled_actions": [],
  },
];

const workQueuePreviewMails = {
  "m0a80001-0000-4000-8000-000000000007": {
    "mail_id": "m0a80001-0000-4000-8000-000000000007",
    "subject": "[수량변경] 냉동 딸기 IQF 홀 주문 수량 정정",
    "sender": "sales@a-supplier.example.com",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-19T02:20:00Z",
    "body_text":
        "안녕하세요, A사입니다.\n\n앞서 말씀드린 월 1,000kg을 월 1,500kg으로 정정합니다.\n\n감사합니다.",
    "attachments": [],
  },
  "m0a80001-0000-4000-8000-000000000006": {
    "mail_id": "m0a80001-0000-4000-8000-000000000006",
    "subject": "[견적 요청] 깐마늘 공급 단가 문의",
    "sender": "buy@e-mart.example",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-19T03:05:00Z",
    "body_text":
        "안녕하세요, E사 구매담당입니다.\n\n깐마늘 국내산 공급 단가 견적 부탁드립니다.\n납품 일정은 추후 안내드리겠습니다.\n\n감사합니다.",
    "attachments": [],
  },
  "m0a80001-0000-4000-8000-000000000005": {
    "mail_id": "m0a80001-0000-4000-8000-000000000005",
    "subject": "[단가변경] 깐마늘 1kg 공급 단가 조정",
    "sender": "sales@f-farm.example",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-19T02:40:00Z",
    "body_text":
        "구매팀 담당자님께,\n\n12월부터 깐마늘 1kg 단가를 9,800원에서 11,200원으로 조정합니다.\n\nF농장 드림",
    "attachments": [],
  },
  "m0a80001-0000-4000-8000-000000000004": {
    "mail_id": "m0a80001-0000-4000-8000-000000000004",
    "subject": "[단가인상] 냉동 딸기 IQF 홀 10kg 단가 조정",
    "sender": "sales@a-supplier.example.com",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-19T02:10:00Z",
    "body_text":
        "안녕하세요, A사입니다.\n\n11월 납품분부터 냉동 딸기 IQF 홀 10kg 박스 단가를 kg당 5,500원에서 5,900원으로 조정하게 되었습니다.\n월 1,000kg 기준이며 HACCP 인증 제품입니다.\n\n감사합니다.",
    "attachments": [],
  },
  "m0a80001-0000-4000-8000-000000000003": {
    "mail_id": "m0a80001-0000-4000-8000-000000000003",
    "subject": "[단가변경] 11월 제주감귤 공급단가 조정 안내",
    "sender": "sales@a-farm.example",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-19T01:24:00Z",
    "body_text": "안녕하세요, A사 영업담당입니다.\n\n원물 수급 사정으로 11월 1일 납품분부터 제주감귤(10kg) 공급단가를 박스당 32,000원에서 35,000원으로 조정하게 되었습니다.\n자세한 내용은 첨부 단가표를 확인 부탁드립니다.\n\n감사합니다.",
    "attachments": [
      {
        "attachment_id": "a0a80001-0000-4000-8000-000000000031",
        "filename": "A사_11월_단가표.pdf",
        "mime_type": "application/pdf",
        "size_bytes": 182400,
      },
    ],
  },
  "m0a80001-0000-4000-8000-000000000002": {
    "mail_id": "m0a80001-0000-4000-8000-000000000002",
    "subject": "[단가변경] 제주감귤 견적 단가 확인 요청",
    "sender": "order@d-food.example",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-19T00:48:00Z",
    "body_text": "구매팀 담당자님께,\n\n다음 달부터 제주감귤 견적 단가가 변경될 예정입니다. 변경 단가에 대한 확인 회신 부탁드립니다.\n\nD사 드림",
    "attachments": [],
  },
  "m0a80001-0000-4000-8000-000000000001": {
    "mail_id": "m0a80001-0000-4000-8000-000000000001",
    "subject": "[단가변경] 냉동 딸기 공급 조건 변경의 건",
    "sender": "biz@d-food.example",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-18T07:30:00Z",
    "body_text": "공급 조건 변경 안내드립니다. 첨부 문서를 확인해 주세요.",
    "attachments": [
      {
        "attachment_id": "a0a80001-0000-4000-8000-000000000011",
        "filename": "공급조건_변경안.pdf",
        "mime_type": "application/pdf",
        "size_bytes": 96000,
      },
    ],
  },
  "m0a80001-0000-4000-8000-000000000000": {
    "mail_id": "m0a80001-0000-4000-8000-000000000000",
    "subject": "[검토 완료] 냉동 딸기 단가 조정 안내",
    "sender": "sales@a-farm.example",
    "recipients": ["buyer@costflow.example"],
    "received_at": "2026-10-18T00:12:00Z",
    "body_text": "10월 단가 조정 안내입니다.",
    "attachments": [
      {
        "attachment_id": "a0a80001-0000-4000-8000-000000000001",
        "filename": "단가표_10월.xlsx",
        "mime_type":
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "size_bytes": 24300,
      },
      {
        "attachment_id": "a0a80001-0000-4000-8000-000000000002",
        "filename": "품질인증서.pdf",
        "mime_type": "application/pdf",
        "size_bytes": 410000,
      },
    ],
  },
};

/// API-11 형식의 합성 후보 세트(업무 ID별). 필수 조건 불충족 후보는 고를 수 없습니다.
const workQueuePreviewCandidateSets = {
  "c0a80001-0000-4000-8000-000000000007": {
    "candidate_set_id": "cs-preview-0007",
    "revision": 1,
    "selected_supplier_ids": [],
    "is_stale": true,
    "unknown_fields": ["quantity"],
    "allowed_actions": [],
    "disabled_actions": [
      {
        "action": "SELECT_CANDIDATES",
        "reason_code": "REVISION_CONFLICT",
        "message": "입력이 바뀌어 후보를 다시 확인해야 합니다.",
      },
    ],
    "items": [
      {
        "supplier_id": "s-preview-b",
        "name": "B사",
        "contact_email": "order@b-supplier.example.com",
        "handling_evidence": "10월 냉동 딸기 IQF 홀 실거래 2회",
        "reason": "정정 전 수량(월 1,000kg) 기준으로 고른 후보예요.",
        "preference_score": 82,
        "is_web_candidate": false,
        "checks": [
          {"label": "IQF 홀(전체)", "status": "MET", "required": true},
          {"label": "월 1,000kg 공급", "status": "MET", "required": true},
        ],
      },
    ],
  },
  "c0a80001-0000-4000-8000-000000000004": {
    "candidate_set_id": "cs-preview-0004",
    "revision": 1,
    "selected_supplier_ids": [],
    "is_stale": false,
    "unknown_fields": [],
    "allowed_actions": ["SELECT_CANDIDATES"],
    "disabled_actions": [],
    "items": [
      {
        "supplier_id": "s-preview-b",
        "name": "B사",
        "contact_email": "order@b-supplier.example.com",
        "handling_evidence": "10월 냉동 딸기 IQF 홀 실거래 2회",
        "reason": "최근 같은 규격 실거래가 있고 필수 조건을 모두 충족해요.",
        "preference_score": 82,
        "is_web_candidate": false,
        "checks": [
          {"label": "IQF 홀(전체)", "status": "MET", "required": true},
          {"label": "HACCP", "status": "MET", "required": true},
          {"label": "월 1,000kg 공급", "status": "UNKNOWN", "required": true},
          {"label": "국내산", "status": "MET", "required": false},
        ],
      },
      {
        "supplier_id": "s-preview-d",
        "name": "D사",
        "contact_email": "quote@d-supplier.example.com",
        "handling_evidence": "등록 취급 품목: 냉동 딸기(IQF 홀·슬라이스)",
        "reason": "등록 품목에 IQF 홀이 있어요.",
        "caution": {
          "reason": "HACCP 인증을 확인하지 못했어요",
          "evidence_refs": ["supplier-item:d"],
        },
        "unknown_fields": ["certifications"],
        "preference_score": 74,
        "is_web_candidate": false,
        "checks": [
          {"label": "IQF 홀(전체)", "status": "MET", "required": true},
          {"label": "HACCP", "status": "UNKNOWN", "required": true},
          {"label": "월 1,000kg 공급", "status": "MET", "required": true},
        ],
      },
      {
        "supplier_id": "s-preview-c",
        "name": "C사",
        "contact_email": "biz@c-supplier.example.com",
        "handling_evidence": "등록 취급 품목: 냉동 딸기(슬라이스만)",
        "reason": "냉동 딸기를 취급하지만 IQF 홀은 없어요.",
        "preference_score": 61,
        "is_web_candidate": false,
        "checks": [
          {"label": "IQF 홀(전체)", "status": "UNMET", "required": true},
          {"label": "HACCP", "status": "MET", "required": true},
        ],
      },
      {
        "supplier_id": "s-preview-web-1",
        "name": "그린팜푸드",
        "contact_email": "sales@greenfarm.example.com",
        "handling_evidence": "웹 상품 페이지: 냉동 딸기 10kg (2026-10 확인)",
        "reason": "웹에서 같은 품목 판매 페이지를 찾았어요.",
        "unknown_fields": ["unit_price", "certifications"],
        "preference_score": null,
        "is_web_candidate": true,
        "checks": [
          {"label": "IQF 홀(전체)", "status": "UNKNOWN", "required": true},
          {"label": "HACCP", "status": "UNKNOWN", "required": true},
        ],
      },
    ],
  },
};

/// UI 미리보기·테스트용 PDF 첨부(영문 한 페이지). 실제 첨부는 API-26에서 받습니다.
const workQueuePreviewPdfBase64 =
    "JVBERi0xLjQKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5k"
    "b2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFszIDAgUl0gL0NvdW50IDEgPj4K"
    "ZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3gg"
    "WzAgMCA1OTUgODQyXSAvUmVzb3VyY2VzIDw8IC9Gb250IDw8IC9GMSA1IDAgUiA+PiA+PiAv"
    "Q29udGVudHMgNCAwIFIgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL0xlbmd0aCAyMDUgPj4Kc3Ry"
    "ZWFtCkJUIC9GMSAyMCBUZiA1NiA3NjAgVGQgKEdZRU9OSldPIHByZXZpZXcgYXR0YWNobWVu"
    "dCkgVGogRVQKQlQgL0YxIDEyIFRmIDU2IDczMCBUZCAoU3ludGhldGljIFBERiBmb3IgdGhl"
    "IFVJIHByZXZpZXcgcGFnZSBhbmQgdGVzdHMuKSBUaiBFVApCVCAvRjEgMTIgVGYgNTYgNzAw"
    "IFRkIChSZWFsIGF0dGFjaG1lbnRzIGNvbWUgZnJvbSBBUEktMjYuKSBUaiBFVAplbmRzdHJl"
    "YW0KZW5kb2JqCjUgMCBvYmoKPDwgL1R5cGUgL0ZvbnQgL1N1YnR5cGUgL1R5cGUxIC9CYXNl"
    "Rm9udCAvSGVsdmV0aWNhID4+CmVuZG9iagp4cmVmCjAgNgowMDAwMDAwMDAwIDY1NTM1IGYg"
    "CjAwMDAwMDAwMDkgMDAwMDAgbiAKMDAwMDAwMDA1OCAwMDAwMCBuIAowMDAwMDAwMTE1IDAw"
    "MDAwIG4gCjAwMDAwMDAyNDEgMDAwMDAgbiAKMDAwMDAwMDQ5NiAwMDAwMCBuIAp0cmFpbGVy"
    "Cjw8IC9TaXplIDYgL1Jvb3QgMSAwIFIgPj4Kc3RhcnR4cmVmCjU2NgolJUVPRgo=";
