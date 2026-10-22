// Static values used by the purchase review design preview.

const supplierPreviews = [
  SupplierPreviewData(
    'A',
    '5,500',
    '계약 물량 기준',
    '미확인',
    '120,000원 / 월',
    '30,000원 / 월',
    '3,300,000',
    true,
  ),
  SupplierPreviewData(
    'B',
    '5,200',
    '500kg',
    '자료상 7일',
    '미확인',
    '미확인',
    '3,120,000',
    false,
  ),
  SupplierPreviewData(
    'C',
    '5,350',
    '400kg',
    '자료상 10일',
    '미확인',
    '미확인',
    '3,210,000',
    false,
  ),
];

class SupplierPreviewData {
  const SupplierPreviewData(
    this.letter,
    this.price,
    this.minimum,
    this.leadTime,
    this.shipping,
    this.logistics,
    this.purchaseAmount,
    this.existing,
  );
  final String letter,
      price,
      minimum,
      leadTime,
      shipping,
      logistics,
      purchaseAmount;
  final bool existing;
}
