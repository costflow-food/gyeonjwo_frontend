import "dart:typed_data";

import "candidate.dart";
import "work_case.dart";

abstract interface class WorkQueueRepository {
  /// API-01. 상태·검색을 바꾸면 cursor 없이 처음부터 조회합니다.
  /// [limit]은 한 페이지 건수(서버 기본 25, 최대 100)입니다.
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
  });

  /// API-25. 읽기 전용이며 추출을 시작하지 않습니다.
  Future<OriginalMail> getOriginalMail(String mailId);

  /// API-26. 첨부 원본 바이트(읽기 전용).
  Future<Uint8List> getAttachmentContent(String mailId, String attachmentId);

  /// API-05. 되돌릴 수 없습니다: 업무와 연결 메일이 삭제됩니다.
  Future<void> acceptIncrease(WorkCase workCase);

  /// API-04. 202 접수만 확인하며 처리 완료를 뜻하지 않습니다.
  Future<void> start(WorkCase workCase);

  /// API-02 + API-25. 목록에 없는 업무(주소로 바로 연 업무)를 엽니다.
  Future<WorkCase> getCase(String caseId);

  /// API-02만 읽어 목록의 업무 한 건을 새 상태로 바꿉니다. 제목·보낸 사람·
  /// 회신 현황처럼 API-02에 없는 값은 [listed]에서 가져옵니다. 보관된
  /// 업무는 목록에서 빠지므로 null입니다.
  Future<WorkCase?> refreshCase(WorkCase listed);

  /// API-07. 사유는 업무 단계에 맞춰 고릅니다([WorkCase.resumeReason]).
  /// 202 접수만 확인하며 처리 완료를 뜻하지 않습니다.
  Future<void> resume(WorkCase workCase);

  /// API-11. 에이전트가 고른 견적 요청 후보.
  Future<CandidateSet> getCandidates(String caseId);

  /// API-12. 고른 업체로 견적 요청 초안을 만들고 업체별 발송 상태를 돌려줍니다.
  Future<List<SelectedDraft>> selectCandidates(
    WorkCase workCase,
    CandidateSet candidates,
    List<String> supplierIds,
  );
}
