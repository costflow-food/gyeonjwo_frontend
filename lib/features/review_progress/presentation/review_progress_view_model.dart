import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/review_phase.dart";
import "../../purchase_review/presentation/purchase_review_view_model.dart";

part "review_progress_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

// One retained state per request. Closing a dialog does not cancel its Future.
@Riverpod(keepAlive: true, retry: _noRetry)
class ReviewProgressViewModel extends _$ReviewProgressViewModel {
  @override
  FutureOr<ReviewPhase> build(String requestId) => ReviewPhase.idle;

  Future<void> start() async {
    if (state.isLoading || state.asData?.value == ReviewPhase.completed) return;
    state = const AsyncLoading();
    final resultProvider = purchaseReviewViewModelProvider(requestId);
    try {
      if (ref.read(resultProvider).hasError) ref.invalidate(resultProvider);
      // Use the existing DataSource -> Repository -> ViewModel request and cache.
      await ref.read(resultProvider.future);
      if (ref.mounted) state = const AsyncData(ReviewPhase.completed);
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(error, stackTrace);
    }
  }
}
