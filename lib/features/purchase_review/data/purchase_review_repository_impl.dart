import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/purchase_review.dart";
import "../domain/purchase_review_repository.dart";
import "purchase_review_data_source.dart";

part 'purchase_review_repository_impl.g.dart';

@Riverpod(keepAlive: true)
PurchaseReviewRepository purchaseReviewRepository(Ref ref) {
  return PurchaseReviewRepositoryImpl(
    ref.watch(purchaseReviewDataSourceProvider),
  );
}

class PurchaseReviewRepositoryImpl implements PurchaseReviewRepository {
  const PurchaseReviewRepositoryImpl(this._dataSource);

  final PurchaseReviewDataSource _dataSource;

  @override
  Future<PurchaseReview> getReview(String requestId) async {
    final json = await _dataSource.fetchReview(requestId);
    return PurchaseReview(
      requestId: json["requestId"] as String,
      title: json["title"] as String,
      supplierName: json["supplierName"] as String,
      specification: json["specification"] as String,
      effectiveDate: json["effectiveDate"] as String,
      periodLabel: json["periodLabel"] as String,
      existingUnitPrice: json["existingUnitPrice"] as int,
      requestedUnitPrice: json["requestedUnitPrice"] as int,
      reviewQuantity: json["reviewQuantity"] as int,
      plannedQuantity: json["plannedQuantity"] as int,
      fixedQuantity: json["fixedQuantity"] as int,
      monthlyCostImpact: json["monthlyCostImpact"] as int,
      impactNote: json["impactNote"] as String,
      costNote: json["costNote"] as String,
      sourceNote: json["sourceNote"] as String,
      suppliers: (json["suppliers"] as List)
          .map((entry) {
            final supplier = entry as Map<String, dynamic>;
            return SupplierQuote(
              letter: supplier["letter"] as String,
              unitPrice: supplier["unitPrice"] as int,
              minimum: supplier["minimum"] as String,
              leadTime: supplier["leadTime"] as String,
              shippingMonthlyCost: supplier["shippingMonthlyCost"] as int?,
              logisticsMonthlyCost: supplier["logisticsMonthlyCost"] as int?,
              purchaseAmount: supplier["purchaseAmount"] as int,
              monthlyTotalCost: supplier["monthlyTotalCost"] as int?,
              existing: supplier["existing"] as bool,
              specification: supplier["specification"] as String,
              stock: supplier["stock"] as String,
              monthlyCostNote: supplier["monthlyCostNote"] as String,
            );
          })
          .toList(growable: false),
    );
  }
}
