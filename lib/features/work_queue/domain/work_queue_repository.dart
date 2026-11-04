import "dart:typed_data";

import "candidate.dart";
import "work_case.dart";

abstract interface class WorkQueueRepository {
  /// API-01. 상태·검색을 바꾸면 cursor 없이 처음부터 조회합니다.
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
  });

  /// API-25. 읽기 전용이며 추출을 시작하지 않습니다.
  Future<OriginalMail> getOriginalMail(String mailId);

  /// API-26. 첨부 원본 바이트(읽기 전용).
  Future<Uint8List> getAttachmentContent(String mailId, String attachmentId);

  /// API-05. 되돌릴 수 없습니다: 업무와 연결 메일이 삭제됩니다.
  Future<void> acceptIncrease(WorkCase workCase);

  /// API-04. 202 접수만 확인하며 처리 완료를 뜻하지 않습니다.
  Future<void> start(WorkCase workCase);

  /// API-03. 저장된 진행 단계와 보류·오류 코드(실행 없음).
  Future<CaseProgress> getProgress(String caseId);

  /// API-07 `reason=RESUME_HOLD`. 202 접수만 확인하며 추출 완료를 뜻하지 않습니다.
  Future<void> resume(WorkCase workCase);

  /// API-11. 에이전트가 고른 견적 요청 후보.
  Future<CandidateSet> getCandidates(String caseId);

  /// API-12. 고른 업체로 견적 요청 초안을 만듭니다(승인 ON이면 승인 대기).
  Future<void> selectCandidates(
    WorkCase workCase,
    CandidateSet candidates,
    List<String> supplierIds,
  );
}
