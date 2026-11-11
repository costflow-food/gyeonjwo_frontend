import "supplier.dart";

abstract interface class SupplierRepository {
  /// API-29. A new query starts without a cursor.
  Future<SupplierPage> getSuppliers({String query = "", String? cursor});

  Future<SupplierDetail> getSupplier(String supplierId);

  Future<PriceHistory> getPriceHistory(String supplierItemId);

  /// Pre-registers reference data. Retrying the same draft reuses one
  /// idempotency key.
  ///
  /// 08에 등록 API가 없어 실제 서버로는 보내지 않고
  /// `SUPPLIER_REGISTRATION_UNSUPPORTED`로 실패합니다.
  Future<SupplierDetail> registerSupplier(SupplierDraft draft);
}
