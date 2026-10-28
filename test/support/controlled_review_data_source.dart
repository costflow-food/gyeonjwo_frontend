import "dart:async";

import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_preview_data.dart";

class ControlledReviewDataSource implements PurchaseReviewDataSource {
  final calls = <String, int>{};
  final _pending = <String, Completer<Map<String, dynamic>>>{};

  @override
  Future<Map<String, dynamic>> fetchReview(String requestId) {
    calls.update(requestId, (count) => count + 1, ifAbsent: () => 1);
    final pending = Completer<Map<String, dynamic>>();
    _pending[requestId] = pending;
    return pending.future;
  }

  void succeed(String requestId) => _pending[requestId]!.complete(
    Map<String, dynamic>.from(purchaseReviewPreviewResponses[requestId]!),
  );

  void fail(String requestId) => _pending[requestId]!.completeError(
    StateError("상세 조회 실패"),
    StackTrace.current,
  );
}
