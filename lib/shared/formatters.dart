String formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
    (match) => "${match[1]},",
  );
}

String formatMonthlyCost(int? value) =>
    value == null ? "미확인" : "${formatNumber(value)}원 / 월";

/// 서버 Decimal 문자열("5500", "1234.50")에 천 단위 구분을 넣습니다.
/// double로 바꾸지 않아 정밀도를 잃지 않습니다.
String formatDecimal(String value) {
  final negative = value.startsWith("-");
  final unsigned = negative ? value.substring(1) : value;
  final parts = unsigned.split(".");
  final whole = parts.first.replaceAllMapped(
    RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
    (match) => "${match[1]},",
  );
  final fraction = parts.length > 1 ? ".${parts[1]}" : "";
  return "${negative ? "-" : ""}$whole$fraction";
}

/// "2026-10-27" → "2026.10.27".
String formatIsoDate(String date) => date.replaceAll("-", ".");

/// UTC ISO 8601 시각을 Asia/Seoul(UTC+9, 일광절약시간 없음) 기준으로 표시합니다.
String formatSeoulDateTime(String isoUtc) {
  final parsed = DateTime.tryParse(isoUtc);
  if (parsed == null) return isoUtc;
  final seoul = parsed.toUtc().add(const Duration(hours: 9));
  String two(int value) => value.toString().padLeft(2, "0");
  return "${seoul.year}.${two(seoul.month)}.${two(seoul.day)} "
      "${two(seoul.hour)}:${two(seoul.minute)}";
}

/// 950 → "950ms", 1200 → "1.2초", 30000 → "30초".
String formatDuration(int milliseconds) {
  if (milliseconds < 1000) return "${milliseconds}ms";
  if (milliseconds % 1000 == 0) return "${milliseconds ~/ 1000}초";
  return "${(milliseconds / 1000).toStringAsFixed(1)}초";
}
