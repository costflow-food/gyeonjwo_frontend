import "../../../../shared/formatters.dart";

/// 서버 Decimal("5500.000000")을 "5,500"처럼 보여 줍니다. 소수 끝의 0만 지웁니다.
String decimal(String value) {
  var text = value;
  if (text.contains(".")) {
    text = text.replaceFirst(RegExp(r"0+$"), "");
    if (text.endsWith(".")) text = text.substring(0, text.length - 1);
  }
  return formatDecimal(text);
}

String won(String? value) => value == null ? "미확인" : "${decimal(value)}원";

String perUnit(String? price, String? unit) =>
    price == null ? "미확인" : "${decimal(price)}원${unit == null ? "" : " / $unit"}";
