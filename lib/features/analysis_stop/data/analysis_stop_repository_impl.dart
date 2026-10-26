import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/analysis_stop.dart";
import "../domain/analysis_stop_repository.dart";
import "analysis_stop_data_source.dart";

part 'analysis_stop_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AnalysisStopRepository analysisStopRepository(Ref ref) {
  return AnalysisStopRepositoryImpl(ref.watch(analysisStopDataSourceProvider));
}

class AnalysisStopRepositoryImpl implements AnalysisStopRepository {
  const AnalysisStopRepositoryImpl(this._dataSource);

  final AnalysisStopDataSource _dataSource;

  @override
  Future<AnalysisStop> getStopReason(String requestId) async {
    final json = await _dataSource.fetchStopReason(requestId);
    return AnalysisStop(
      requestId: json["requestId"] as String,
      stageLabel: json["stageLabel"] as String,
      summary: json["summary"] as String,
      guidance: json["guidance"] as String,
      issues: (json["issues"] as List)
          .map((entry) {
            final issue = entry as Map<String, dynamic>;
            return StopIssue(
              code: issue["code"] as String,
              label: issue["label"] as String,
              message: issue["message"] as String,
              sourceLocation: issue["sourceLocation"] as String,
            );
          })
          .toList(growable: false),
    );
  }
}
