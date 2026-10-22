import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "purchase_review_preview_data.dart";

final purchaseReviewDataSourceProvider = Provider<PurchaseReviewDataSource>(
  (ref) => const PreviewPurchaseReviewDataSource(),
);

abstract interface class PurchaseReviewDataSource {
  Future<Map<String, dynamic>> fetchReview(String requestId);
}

class PreviewPurchaseReviewDataSource implements PurchaseReviewDataSource {
  const PreviewPurchaseReviewDataSource({
    this.latency = const Duration(milliseconds: 250),
  });

  final Duration latency;

  @override
  Future<Map<String, dynamic>> fetchReview(String requestId) async {
    await Future<void>.delayed(latency);
    final response = purchaseReviewPreviewResponses[requestId];
    if (response == null) {
      throw StateError("요청에 대한 검토 결과가 없습니다: $requestId");
    }
    return jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
  }
}
