import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/purchase_review_repository_impl.dart";
import "../domain/purchase_review.dart";

part 'purchase_review_view_model.g.dart';

// null을 반환하면 자동 재시도 없이 사용자의 다시 시도만 기다립니다.
Duration? _noRetry(int retryCount, Object error) => null;

// _$ 클래스와 Provider 선언은 build_runner가 생성합니다.
@Riverpod(keepAlive: true, retry: _noRetry)
class PurchaseReviewViewModel extends _$PurchaseReviewViewModel {
  @override
  // build 인자가 요청별 Provider를 만듭니다: purchaseReviewViewModelProvider(id).
  Future<PurchaseReview> build(String requestId) {
    return ref.watch(purchaseReviewRepositoryProvider).getReview(requestId);
  }

  void refresh() => ref.invalidateSelf();
}
