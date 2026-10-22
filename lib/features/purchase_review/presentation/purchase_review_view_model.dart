import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/purchase_review_repository_impl.dart";
import "../domain/purchase_review.dart";

// Kept alive per request while the app is running, including after navigation.
final purchaseReviewViewModelProvider =
    AsyncNotifierProvider.family<
      PurchaseReviewViewModel,
      PurchaseReview,
      String
    >(PurchaseReviewViewModel.new, retry: (_, _) => null);

class PurchaseReviewViewModel extends AsyncNotifier<PurchaseReview> {
  PurchaseReviewViewModel(this.requestId);

  final String requestId;

  @override
  Future<PurchaseReview> build() {
    return ref.watch(purchaseReviewRepositoryProvider).getReview(requestId);
  }

  void refresh() => ref.invalidateSelf();
}
