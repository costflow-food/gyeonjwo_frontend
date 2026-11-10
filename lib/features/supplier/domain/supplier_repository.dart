import "supplier.dart";

abstract interface class SupplierRepository {
  /// API-29. A new query starts without a cursor.
  Future<SupplierPage> getSuppliers({String query = "", String? cursor});

  /// API-30.
  Future<SupplierDetail> getSupplier(String supplierId);

  /// API-31. Quotes and purchases come back separately.
  Future<PriceHistory> getPriceHistory(String supplierItemId);

  /// Pre-registers reference data. Retrying the same draft reuses one
  /// idempotency key.
  ///
  /// 08에 등록 API가 없어 실제 서버로는 보내지 않고
  /// `SUPPLIER_REGISTRATION_UNSUPPORTED`로 실패합니다. 화면에도 등록 진입점이
  /// 없으며, 서버 지원이 합의되면 데이터 소스만 연결합니다.
  Future<SupplierDetail> registerSupplier(SupplierDraft draft);
}
