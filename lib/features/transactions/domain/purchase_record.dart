/// 확정 거래 한 건 = `purchase_history` 한 행 + 품목(`supplier_items`)·거래처
/// (`suppliers`) 이름 (`docs/design-ssot.md` 7.12).
///
/// DB에 있는 열만 둡니다. 확정 방식·증빙 파일·연결된 업무는 DB에도 API에도
/// 없어 넣지 않습니다(7.12 데이터 규칙).
class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.supplierItemId,
    required this.supplierId,
    required this.itemName,
    required this.supplierName,
    required this.transactionDate,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalAmount,
    required this.currency,
    this.specification,
  });

  /// `purchase_history.id`.
  final String id;

  /// `purchase_history.supplier_item_id`.
  final String supplierItemId;

  /// `purchase_history.supplier_id`.
  final String supplierId;

  /// `supplier_items.item_name`.
  final String itemName;

  /// `supplier_items.specification`. 모르면 null.
  final String? specification;

  /// `suppliers.name`.
  final String supplierName;

  /// `purchase_history.transaction_date` (YYYY-MM-DD).
  final String transactionDate;

  /// `purchase_history.quantity`.
  final num quantity;

  /// `purchase_history.unit` (예: kg).
  final String unit;

  /// `purchase_history.unit_price`.
  final num unitPrice;

  /// `purchase_history.total_amount`.
  final num totalAmount;

  /// `purchase_history.currency` (예: KRW).
  final String currency;

  DateTime get date => DateTime.parse(transactionDate);
}
