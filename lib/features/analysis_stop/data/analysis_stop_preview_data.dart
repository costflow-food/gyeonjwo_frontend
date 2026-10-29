// Mock API response. Only the preview DataSource reads this fixture.
// 09 화면 흐름도 SCR-006 합성 사례: 비교 가능한 품목 규격 미확인으로 전체 분석 중단.
const analysisStopPreviewResponses = {
  "REQ-2026-1018-003": {
    "requestId": "REQ-2026-1018-003",
    "outcome": "REVIEW_REQUIRED",
    "stageLabel": "요청 규격 확인 단계",
    "issues": [
      {
        "code": "ITEM_SPEC_MISMATCH",
        "label": "비교 가능한 품목 규격",
        "message": "냉동·무가당 여부와 포장 규격을 확인할 수 없습니다.",
        "sourceLocation": "메일 본문·첨부 요청서 전체",
      },
    ],
    "summary": "필수 조건이 확인되지 않아 전체 분석을 중단한 합성 사례입니다.",
    "guidance":
        "담당자는 기존 업무 절차로 거래처에 규격과 비용 조건을 재확인할 수 있습니다. 새 회신은 새 업무로 접수합니다.",
    "resultPersisted": false,
  },
};
