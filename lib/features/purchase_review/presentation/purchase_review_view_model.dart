import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../work_queue/presentation/work_queue_view_model.dart";
import "../data/purchase_review_repository_impl.dart";
import "../domain/purchase_review.dart";
import "../domain/purchase_review_repository.dart";

part "purchase_review_view_model.g.dart";

// null을 반환하면 자동 재시도 없이 사용자의 다시 시도만 기다립니다.
Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(retry: _noRetry)
class PurchaseReviewViewModel extends _$PurchaseReviewViewModel {
  @override
  Future<PurchaseReview> build(String caseId) =>
      ref.watch(purchaseReviewRepositoryProvider).getReview(caseId);

  void refresh() => ref.invalidateSelf();

  Future<void> selectPlan(ResponsePlan plan) => _decide(
    (repository, card) => repository.selectPlan(card, plan),
  );

  Future<void> hold(String note) =>
      _decide((repository, card) => repository.hold(card, note));

  Future<void> confirmReview() =>
      _decide((repository, card) => repository.confirmReview(card));

  Future<void> _decide(
    Future<void> Function(PurchaseReviewRepository repository, ReviewCard card) send,
  ) async {
    final card = state.requireValue.card;
    try {
      await send(ref.read(purchaseReviewRepositoryProvider), card);
    } on PurchaseReviewFailure catch (failure) {
      // A retryable failure may still have gone through; read it again.
      if ((failure.cardChanged || failure.retryable) && ref.mounted) {
        ref.invalidateSelf();
      }
      rethrow;
    }
    if (!ref.mounted) return;
    ref.invalidateSelf();
    ref.invalidate(workQueueViewModelProvider);
    ref.invalidate(caseDetailProvider(caseId));
  }
}
