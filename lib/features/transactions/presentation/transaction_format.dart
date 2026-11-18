import "../../../shared/formatters.dart";
import "../domain/purchase_record.dart";
import "../domain/transaction_listing.dart";

/// 1000 → "1,000", 12.5 → "12.5".
String formatAmount(num value) => value == value.roundToDouble()
    ? formatNumber(value.toInt())
    : formatDecimal(value.toString());

/// 8.0 → "8", 5.4 → "5.4" (소수 1자리, 정수면 소수 없이).
String formatPercent(num value) {
  final abs = value.abs();
  return abs == abs.roundToDouble()
      ? abs.toInt().toString()
      : abs.toStringAsFixed(1);
}

/// 통화 글자. KRW만 '원'이고 나머지는 통화 코드를 그대로 씁니다.
String currencyText(String currency) => currency == "KRW" ? "원" : currency;

/// "1,000kg".
String quantityText(PurchaseRecord record) =>
    "${formatAmount(record.quantity)}${record.unit}";

/// "5,400원/kg".
String unitPriceText(PurchaseRecord record) =>
    "${formatAmount(record.unitPrice)}${currencyText(record.currency)}/${record.unit}";

/// "5,400,000원".
String totalText(PurchaseRecord record) =>
    "${formatAmount(record.totalAmount)}${currencyText(record.currency)}";

/// "2026.10.18".
String dateText(PurchaseRecord record) => formatIsoDate(record.transactionDate);

/// 직전 거래 대비 글자: '▲ 400원 · +8%', '▼ 100원 · −2%', '직전과 같음', '첫 거래'.
String changeText(PurchaseRecord record, PriceChange change) {
  if (change.isFirst) return "첫 거래";
  if (change.difference == 0) return "직전과 같음";
  final up = change.difference > 0;
  return "${up ? "▲" : "▼"} ${formatAmount(change.difference.abs())}"
      "${currencyText(record.currency)} · ${up ? "+" : "−"}"
      "${formatPercent(change.percent)}%";
}

/// 툴팁: '직전 2026.10.10 한라푸드 5,000원/kg 대비'. 첫 거래면 null.
String? changeTooltip(PriceChange change) {
  final previous = change.previous;
  if (previous == null) return null;
  return "직전 ${dateText(previous)} ${previous.supplierName} "
      "${unitPriceText(previous)} 대비";
}
