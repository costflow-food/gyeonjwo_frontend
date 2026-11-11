import "purchase_review.dart";

abstract interface class PurchaseReviewRepository {
  /// 최신 저장 카드와 그 근거 견적. 카드가 없으면 [PurchaseReviewFailure.notReady].
  Future<PurchaseReview> getReview(String caseId);

  /// API-13 견적만. 검토 카드가 아직 없어도 읽을 수 있습니다.
  Future<List<QuoteVersion>> getQuotes(String caseId);

  Future<void> selectPlan(ReviewCard card, ResponsePlan plan);

  /// API-15 HOLD. 카드가 있는 뒤의 보류라 review_revision과 사유가 필요합니다.
  Future<void> hold(ReviewCard card, String note);

  /// API-15 CONFIRM_REVIEW. 확인과 보관을 함께 기록합니다.
  Future<void> confirmReview(ReviewCard card);
}
