import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "purchase_review_preview_data.dart";

part 'purchase_review_data_source.g.dart';

@Riverpod(keepAlive: true)
PurchaseReviewDataSource purchaseReviewDataSource(Ref ref) {
  return const PreviewPurchaseReviewDataSource();
}

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
