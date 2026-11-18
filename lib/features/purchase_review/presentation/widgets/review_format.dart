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

/// "5,800원/kg": 붙여 쓴 단가(배분 표·역제안 문장).
String perUnitTight(String? price, String? unit) =>
    price == null ? "미확인" : "${decimal(price)}원${unit == null ? "" : "/$unit"}";

/// 마지막 글자에 받침이 있는지. 한글이 아니면 읽는 소리로 어림합니다
/// (숫자 1·3·6·7·8·0, 영문 l·m·n·g → kg은 '킬로그램').
bool hasFinalConsonant(String text) {
  final trimmed = text.trimRight();
  if (trimmed.isEmpty) return false;
  final last = trimmed.codeUnitAt(trimmed.length - 1);
  if (last >= 0xAC00 && last <= 0xD7A3) return (last - 0xAC00) % 28 != 0;
  final char = String.fromCharCode(last).toLowerCase();
  return "0136789lmng".contains(char);
}

/// 받침에 따라 조사를 고릅니다: `josa("한라푸드", "은", "는")` → "한라푸드는".
String josa(String word, String withFinal, String withoutFinal) =>
    "$word${hasFinalConsonant(word) ? withFinal : withoutFinal}";
