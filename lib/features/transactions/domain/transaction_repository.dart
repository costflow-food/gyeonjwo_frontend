import "purchase_record.dart";

abstract interface class TransactionRepository {
  /// 이 사용자의 확정 거래 전부(순서 없음).
  ///
  /// 직전 거래 대비·단가 흐름은 같은 품목의 이전 거래가 필요해서, 기간으로
  /// 거르기 전 목록을 받습니다.
  Future<List<PurchaseRecord>> getPurchases();
}
