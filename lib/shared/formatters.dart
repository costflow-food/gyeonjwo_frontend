String formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
    (match) => "${match[1]},",
  );
}

String formatMonthlyCost(int? value) =>
    value == null ? "미확인" : "${formatNumber(value)}원 / 월";
