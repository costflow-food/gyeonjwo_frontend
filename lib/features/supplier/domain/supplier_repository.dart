import "supplier.dart";

abstract interface class SupplierRepository {
  /// API-29. A new query starts without a cursor.
  Future<SupplierPage> getSuppliers({String query = "", String? cursor});

  /// API-30.
  Future<SupplierDetail> getSupplier(String supplierId);

  /// API-31. Quotes and purchases come back separately.
  Future<PriceHistory> getPriceHistory(String supplierItemId);

  /// Pre-registers reference data. Retries of one user action reuse
  /// [idempotencyKey].
  Future<SupplierDetail> registerSupplier(
    SupplierDraft draft, {
    required String idempotencyKey,
  });
}
