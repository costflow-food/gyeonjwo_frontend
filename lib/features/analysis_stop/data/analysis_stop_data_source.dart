import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "analysis_stop_preview_data.dart";

part 'analysis_stop_data_source.g.dart';

@Riverpod(keepAlive: true)
AnalysisStopDataSource analysisStopDataSource(Ref ref) {
  return const PreviewAnalysisStopDataSource();
}

abstract interface class AnalysisStopDataSource {
  Future<Map<String, dynamic>> fetchStopReason(String requestId);
}

class PreviewAnalysisStopDataSource implements AnalysisStopDataSource {
  const PreviewAnalysisStopDataSource({
    this.latency = const Duration(milliseconds: 250),
  });

  final Duration latency;

  @override
  Future<Map<String, dynamic>> fetchStopReason(String requestId) async {
    await Future<void>.delayed(latency);
    final response = analysisStopPreviewResponses[requestId];
    if (response == null) {
      throw StateError("요청에 대한 분석 중단 사유가 없습니다: $requestId");
    }
    return jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
  }
}
