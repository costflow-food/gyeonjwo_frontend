// Mock API-16 drafts by case ID. Suppliers, addresses, and prices are synthetic.
// allowed_actions are filled in by the preview DataSource, as the server would.
const mailDraftPreviewDrafts = {
  "REQ-2026-1019-003": [
    {
      "draft_id": "draft-a-counter-1",
      "supplier_name": "A사",
      "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a001",
      "purpose": "COUNTER_OFFER",
      "recipient": "sales@a-supplier.example.com",
      "subject": "[견줘] 11월 냉동 딸기 공급단가 조정 관련 회신",
      "body_text":
          "안녕하세요, 구매팀입니다.\n\n11월 냉동 딸기 공급단가 조정 안내 잘 받았습니다. "
          "현재 확인한 대안 견적을 고려할 때 kg당 5,200원으로 조정이 가능한지 검토 부탁드립니다. "
          "월 1,000kg 기준이며 납기 조건은 기존과 같습니다.\n\n감사합니다.\n구매팀 드림",
      "status": "DRAFT",
      "approval_required": true,
      "input_revision": 4,
      "settings_version": 3,
      "evidence": [
        "A사 단가변경 안내 메일 · 5,000→5,500원/kg, 11월 1일 적용",
        "B사 견적 회신 · 5,400원/kg, 최대 600kg, 배송비 10,000원",
        "목표 단가 5,200원/kg은 회사 역제안 정책 범위 안",
      ],
      "replaces_id": null,
      "sent_at": null,
      "provider_message_id": null,
      "failure_message": null,
    },
    {
      "draft_id": "draft-b-rfq-1",
      "supplier_name": "B사",
      "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a002",
      "purpose": "RFQ",
      "recipient": "order@b-supplier.example.com",
      "subject": "[견줘] 냉동 딸기 견적 요청",
      "body_text":
          "안녕하세요, 구매팀입니다.\n\nIQF 냉동 딸기 10kg 박스 기준으로 월 1,000kg 공급 견적을 요청드립니다. "
          "단가, 최대 공급량, 배송비, 납기를 함께 알려주시면 감사하겠습니다.\n\n구매팀 드림",
      "status": "SENT",
      "approval_required": true,
      "input_revision": 2,
      "settings_version": 2,
      "evidence": ["B사 취급 품목 · 냉동 딸기 IQF 슬라이스 10kg"],
      "replaces_id": null,
      "sent_at": "2026-10-19T02:40:30Z",
      "provider_message_id": "gmail-msg-preview-b1",
      "failure_message": null,
    },
    {
      "draft_id": "draft-c-rfq-1",
      "supplier_name": "C사",
      "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a003",
      "purpose": "RFQ",
      "recipient": "biz@c-supplier.example.com",
      "subject": "[견줘] 냉동 딸기 견적 요청",
      "body_text":
          "안녕하세요, 구매팀입니다.\n\n냉동 딸기 월 1,000kg 공급 견적을 요청드립니다. "
          "HACCP 인증 여부와 단가, 납기를 알려주세요.\n\n구매팀 드림",
      "status": "FAILED",
      "approval_required": true,
      "input_revision": 2,
      "settings_version": 2,
      "evidence": ["C사 기준자료 · 견적 요청 이메일 등록됨"],
      "replaces_id": null,
      "sent_at": null,
      "provider_message_id": null,
      "failure_message": "수신 서버가 주소를 거부했습니다 (550). 수신자를 확인해 주세요.",
    },
    {
      "draft_id": "draft-d-clar-1",
      "supplier_name": "D사",
      "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a004",
      "purpose": "CLARIFICATION",
      "recipient": "quote@d-supplier.example.com",
      "subject": "[견줘] 견적 배송비 확인 요청",
      "body_text":
          "안녕하세요, 구매팀입니다.\n\n보내주신 견적에 배송비 포함 여부가 확인되지 않아 문의드립니다. "
          "1,000kg 기준 배송비를 알려주시면 감사하겠습니다.\n\n구매팀 드림",
      "status": "UNKNOWN",
      "approval_required": false,
      "input_revision": 3,
      "settings_version": 3,
      "evidence": ["D사 견적 회신 · 배송비 미확인", "③ 확인 우선순위 · 배송비가 비교 결과에 영향"],
      "replaces_id": null,
      "sent_at": null,
      "provider_message_id": null,
      "failure_message": null,
    },
  ],
  "REQ-2026-1018-003": [
    {
      "draft_id": "draft-d2-clar-1",
      "supplier_name": "D사",
      "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a004",
      "purpose": "CLARIFICATION",
      "recipient": "quote@d-supplier.example.com",
      "subject": "[견줘] 스캔 견적서 단가 확인 요청",
      "body_text":
          "안녕하세요, 구매팀입니다.\n\n보내주신 스캔 견적서의 단가 칸이 흐려 확인이 어렵습니다. "
          "단가를 메일 본문으로 한 번 더 알려주시면 감사하겠습니다.\n\n구매팀 드림",
      "status": "SENT",
      "approval_required": false,
      "input_revision": 2,
      "settings_version": 3,
      "evidence": ["OCR 결과 · 단가 칸 신뢰도 낮음"],
      "replaces_id": null,
      "sent_at": "2026-10-18T05:45:00Z",
      "provider_message_id": "gmail-msg-preview-d2",
      "failure_message": null,
    },
  ],
};
