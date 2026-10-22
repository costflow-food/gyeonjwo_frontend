// Static values used by the work queue design preview.

const requestPreviews = [
  RequestPreviewData(
    '[단가변경] 11월 냉동 딸기 공급단가 조정 안내',
    'A사',
    1,
    '검토 대기',
    '2026.10.19',
    '10:24',
    '실행',
  ),
  RequestPreviewData(
    '[단가변경] 냉동 딸기 견적 단가 확인 요청',
    'D사',
    1,
    '검토 대기',
    '2026.10.19',
    '09:48',
    '실행',
  ),
  RequestPreviewData(
    '[검토 완료] 냉동 딸기 단가 조정 안내',
    'A사',
    2,
    '완료',
    '2026.10.19',
    '09:12',
    '결과 보기',
  ),
  RequestPreviewData(
    '[단가변경] 냉동 딸기 공급 조건 변경의 건',
    'D사',
    1,
    '검토 필요',
    '2026.10.18',
    '16:30',
    '사유 보기',
  ),
  RequestPreviewData(
    '[검토 완료] 냉동 딸기 11월 단가 사전 검토',
    'A사',
    1,
    '완료',
    '2026.10.18',
    '14:08',
    '결과 보기',
  ),
  RequestPreviewData(
    '10월 상품 안내 및 정기 뉴스레터',
    'F사',
    0,
    '제외',
    '2026.10.18',
    '11:02',
    '원문 보기',
  ),
];

class RequestPreviewData {
  const RequestPreviewData(
    this.title,
    this.supplier,
    this.attachments,
    this.status,
    this.date,
    this.time,
    this.action,
  );
  final String title, supplier, status, date, time, action;
  final int attachments;
}
