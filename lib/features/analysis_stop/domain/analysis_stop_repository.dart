import "analysis_stop.dart";

abstract interface class AnalysisStopRepository {
  Future<AnalysisStop> getStopReason(String requestId);
}
