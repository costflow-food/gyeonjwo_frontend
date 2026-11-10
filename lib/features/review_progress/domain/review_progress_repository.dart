import "../../work_queue/domain/work_case.dart";

/// API-03 검토 진행. 모델은 업무 큐(KAN-112)·보류 안내(KAN-128)와 같은 [CaseProgress]를 씁니다.
abstract interface class ReviewProgressRepository {
  /// 저장된 진행 단계와 보류·오류 코드. 조회만 하며 처리를 시작하지 않습니다.
  Future<CaseProgress> getProgress(String caseId);
}

class ReviewProgressFailure implements Exception {
  const ReviewProgressFailure(this.code, this.message);

  final String code;

  /// 서버가 보낸 문구. 연결 실패처럼 서버 응답이 없으면 화면 문구입니다.
  final String message;

  /// 서버나 DB 기능이 아직 준비되지 않았거나 잠시 응답하지 못함.
  bool get serverNotReady =>
      code == "PROCESSING_UNAVAILABLE" ||
      code == "NETWORK_UNAVAILABLE" ||
      code.startsWith("HTTP_5");

  @override
  String toString() => "ReviewProgressFailure($code)";
}
