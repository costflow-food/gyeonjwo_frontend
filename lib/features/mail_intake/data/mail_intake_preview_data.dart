// Mock API-23 items. Senders, cases, and values are synthetic.
const mailIntakePreviewItems = [
  {
    "mail_id": "mail-intake-0003",
    "subject": "RE: 냉동 딸기 견적 요청",
    "sender": "order@b-supplier.example.com",
    "received_at": "2026-10-19T04:10:00Z",
    "body_text":
        "안녕하세요, B사입니다.\n\n요청하신 냉동 딸기 견적 회신드립니다. "
        "IQF 슬라이스 10kg 박스 kg당 5,400원, 월 최대 600kg 공급 가능합니다.\n\n감사합니다.",
    "mail_classification": "AMBIGUOUS",
    "reason_detail": "같은 품목의 활성 업무가 2건이고 답장 헤더가 둘 다와 맞지 않습니다.",
    "attachments": ["B사_견적서_1019.pdf"],
    "revision": 1,
    "candidates": [
      {
        "case_id": "REQ-2026-1019-003",
        "title": "[단가변경] 11월 냉동 딸기 공급단가 조정 안내",
        "status": "Running",
        "item_name": "냉동 딸기",
        "conditions": "IQF · 월 1,000kg · HACCP 필수",
        "difference": "규격이 홀(전체)로 요청됐으나 회신은 슬라이스",
        "reply_evidence": "10월 19일 B사 견적 요청 발송 기록 있음",
      },
      {
        "case_id": "REQ-2026-1018-003",
        "title": "[단가변경] 냉동 딸기 공급 조건 변경의 건",
        "status": "Running",
        "item_name": "냉동 딸기",
        "conditions": "IQF 슬라이스 · 월 500kg",
        "difference": "공급량 조건이 다름 (500kg)",
        "reply_evidence": null,
      },
    ],
  },
  {
    "mail_id": "mail-intake-0002",
    "subject": "11월 단가표 송부",
    "sender": "info@e-farm.example.com",
    "received_at": "2026-10-18T23:40:00Z",
    "body_text":
        "안녕하세요. E농장입니다.\n\n11월 단가표를 첨부드립니다. 거래 관련 문의는 회신 부탁드립니다.",
    "mail_classification": "UNCERTAIN",
    "reason_detail": "등록되지 않은 발신자이며 단가표가 첨부됐지만 요청 내용이 확인되지 않습니다.",
    "attachments": ["E농장_11월_단가표.xlsx"],
    "revision": 1,
    "candidates": [],
  },
];
