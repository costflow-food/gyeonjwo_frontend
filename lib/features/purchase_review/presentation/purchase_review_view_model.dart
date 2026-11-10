import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../work_queue/presentation/work_queue_view_model.dart";
import "../data/purchase_review_repository_impl.dart";
import "../domain/purchase_review.dart";
import "../domain/purchase_review_repository.dart";

part "purchase_review_view_model.g.dart";

// null을 반환하면 자동 재시도 없이 사용자의 다시 시도만 기다립니다.
Duration? _noRetry(int retryCount, Object error) => null;

/// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
///
/// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
/// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.
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
      if (failure.cardChanged && ref.mounted) ref.invalidateSelf();
      rethrow;
    }
    if (!ref.mounted) return;
    ref.invalidateSelf();
    ref.invalidate(workQueueViewModelProvider);
    ref.invalidate(caseDetailProvider(caseId));
  }
}
