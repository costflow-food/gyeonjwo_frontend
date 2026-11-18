import "package:flutter_riverpod/flutter_riverpod.dart";

import "../domain/purchase_record.dart";
import "../domain/transaction_repository.dart";

/// TODO(backend): 확정 거래 목록 API가 아직 없습니다. API가 생기면
/// `purchase_history`(+ `supplier_items`·`suppliers` 이름)를 읽는 구현으로
/// 바꿉니다. 기간으로 거르더라도 같은 품목의 직전 거래는 기간 밖이어도 필요합니다.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => const TransactionSampleRepository(),
);

/// 시연용 예시 데이터(디자인 시안 값 그대로). `purchase_history` 열 모양만
/// 씁니다.
class TransactionSampleRepository implements TransactionRepository {
  const TransactionSampleRepository();

  static const _strawberrySpec = "IQF 홀 / 10kg 박스";

  static const records = <PurchaseRecord>[
    PurchaseRecord(
      id: "sample-purchase-1",
      supplierItemId: "sample-item-strawberry-barun",
      supplierId: "sample-supplier-barun",
      itemName: "냉동 딸기",
      specification: _strawberrySpec,
      supplierName: "바른채소",
      transactionDate: "2026-10-18",
      quantity: 1000,
      unit: "kg",
      unitPrice: 5400,
      totalAmount: 5400000,
      currency: "KRW",
    ),
    PurchaseRecord(
      id: "sample-purchase-2",
      supplierItemId: "sample-item-strawberry-halla",
      supplierId: "sample-supplier-halla",
      itemName: "냉동 딸기",
      specification: _strawberrySpec,
      supplierName: "한라푸드",
      transactionDate: "2026-10-10",
      quantity: 800,
      unit: "kg",
      unitPrice: 5000,
      totalAmount: 4000000,
      currency: "KRW",
    ),
    PurchaseRecord(
      id: "sample-purchase-3",
      supplierItemId: "sample-item-tangerine-namdo",
      supplierId: "sample-supplier-namdo",
      itemName: "한라감귤",
      specification: "10kg 박스",
      supplierName: "남도청과",
      transactionDate: "2026-09-25",
      quantity: 600,
      unit: "kg",
      unitPrice: 3900,
      totalAmount: 2340000,
      currency: "KRW",
    ),
    PurchaseRecord(
      id: "sample-purchase-4",
      supplierItemId: "sample-item-strawberry-halla",
      supplierId: "sample-supplier-halla",
      itemName: "냉동 딸기",
      specification: _strawberrySpec,
      supplierName: "한라푸드",
      transactionDate: "2026-09-05",
      quantity: 900,
      unit: "kg",
      unitPrice: 4900,
      totalAmount: 4410000,
      currency: "KRW",
    ),
    PurchaseRecord(
      id: "sample-purchase-5",
      supplierItemId: "sample-item-tangerine-namdo",
      supplierId: "sample-supplier-namdo",
      itemName: "한라감귤",
      specification: "10kg 박스",
      supplierName: "남도청과",
      transactionDate: "2026-08-28",
      quantity: 500,
      unit: "kg",
      unitPrice: 3700,
      totalAmount: 1850000,
      currency: "KRW",
    ),
  ];

  @override
  Future<List<PurchaseRecord>> getPurchases() async => records;
}
