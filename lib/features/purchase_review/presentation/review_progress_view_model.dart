import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/review_progress_repository_impl.dart";
import "../domain/review_progress.dart";

part 'review_progress_view_model.g.dart';

class ReviewProgressState {
  const ReviewProgressState({this.progress, this.failed = false});

  /// 마지막으로 받은 진행 응답. 실패해도 그때까지의 단계를 유지합니다.
  final ReviewProgress? progress;
  final bool failed;
}

// keepAlive로 다이얼로그를 닫아도 진행이 이어지고, 다시 열면 같은 진행을 보여 줍니다.
// 실패 시 자동 재시도는 하지 않습니다. 재실행 정책은 아직 정하지 않았습니다.
@Riverpod(keepAlive: true)
class ReviewProgressViewModel extends _$ReviewProgressViewModel {
  @override
  ReviewProgressState build(String requestId) {
    // Riverpod은 리스너가 없는 Provider의 스트림을 일시정지하므로 직접 구독합니다.
    final subscription = ref
        .watch(reviewProgressRepositoryProvider)
        .watchProgress(requestId)
        .listen(
          (progress) => state = ReviewProgressState(progress: progress),
          onError: (Object _) => state = ReviewProgressState(
            progress: state.progress,
            failed: true,
          ),
        );
    ref.onDispose(subscription.cancel);
    return const ReviewProgressState();
  }
}
