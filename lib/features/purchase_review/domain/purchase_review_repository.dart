import "purchase_review.dart";

abstract interface class PurchaseReviewRepository {
  Future<PurchaseReview> getReview(String requestId);
}
