import "package:riverpod_annotation/riverpod_annotation.dart";

part 'review_progress_data_source.g.dart';

@Riverpod(keepAlive: true)
ReviewProgressDataSource reviewProgressDataSource(Ref ref) {
  return const PreviewReviewProgressDataSource();
}

abstract interface class ReviewProgressDataSource {
  /// 실행한 요청의 진행 응답을 순서대로 전달합니다.
  Stream<Map<String, dynamic>> watchProgress(String requestId);
}

/// 실제 분석 없이 일정 간격으로 단계를 넘기는 합성 시연 응답입니다.
class PreviewReviewProgressDataSource implements ReviewProgressDataSource {
  const PreviewReviewProgressDataSource({
    this.interval = const Duration(milliseconds: 1500),
  });

  static const _totalSteps = 4;

  final Duration interval;

  @override
  Stream<Map<String, dynamic>> watchProgress(String requestId) async* {
    for (var step = 0; step <= _totalSteps; step++) {
      if (step > 0) await Future<void>.delayed(interval);
      yield {
        "requestId": requestId,
        "completedSteps": step,
        "totalSteps": _totalSteps,
        "synthetic": true,
      };
    }
  }
}
