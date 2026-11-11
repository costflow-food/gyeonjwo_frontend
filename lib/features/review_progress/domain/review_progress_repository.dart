import "../../work_queue/domain/work_case.dart";

abstract interface class ReviewProgressRepository {
  Future<CaseProgress> getProgress(String caseId);
}

class ReviewProgressFailure implements Exception {
  const ReviewProgressFailure(this.code, this.message);

  final String code;

  final String message;

  bool get serverNotReady =>
      code == "PROCESSING_UNAVAILABLE" ||
      code == "NETWORK_UNAVAILABLE" ||
      code.startsWith("HTTP_5");

  @override
  String toString() => "ReviewProgressFailure($code)";
}
