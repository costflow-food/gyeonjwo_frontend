/// Normalization and validation for the register form. The server checks
/// again; these only give immediate feedback.
abstract final class SupplierFormRules {
  static const nameMaxLength = 100;

  /// Trims and turns blanks into null (unknown).
  static String? optional(String? value) {
    final trimmed = value?.trim() ?? "";
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? validateName(String? value) {
    final name = optional(value);
    if (name == null) return "업체명을 입력해 주세요.";
    if (name.length > nameMaxLength) {
      return "업체명은 $nameMaxLength자 이내로 입력해 주세요.";
    }
    return null;
  }

  /// Formats 10 digits as 000-00-00000; null for anything else.
  static String? formatBusinessRegistrationNo(String value) {
    final digits = value.replaceAll(RegExp(r"[\s-]"), "");
    if (!RegExp(r"^\d{10}$").hasMatch(digits)) return null;
    return "${digits.substring(0, 3)}-${digits.substring(3, 5)}-"
        "${digits.substring(5)}";
  }

  static String? validateBusinessRegistrationNo(String? value) {
    final raw = optional(value);
    if (raw == null) return null;
    return formatBusinessRegistrationNo(raw) == null
        ? "사업자번호는 숫자 10자리로 입력해 주세요."
        : null;
  }

  static String? validateEmail(String? value) {
    final email = optional(value);
    if (email == null) return null;
    final valid = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(email);
    return valid ? null : "이메일 형식을 확인해 주세요.";
  }

  static String? validatePhone(String? value) {
    final phone = optional(value);
    if (phone == null) return null;
    final valid = RegExp(r"^[0-9+()\-\s]{7,20}$").hasMatch(phone);
    return valid ? null : "전화번호 형식을 확인해 주세요.";
  }

  static String? validateItemName(String? value) =>
      optional(value) == null ? "품목명을 입력해 주세요." : null;

  /// Positive decimal string. Kept as text because the server uses Decimal.
  static String? validatePositiveDecimal(String? value) {
    final number = optional(value);
    if (number == null) return null;
    if (!RegExp(r"^\d+(\.\d+)?$").hasMatch(number)) {
      return "숫자만 입력해 주세요.";
    }
    if (RegExp(r"^0+(\.0+)?$").hasMatch(number)) {
      return "0보다 큰 값을 입력해 주세요.";
    }
    return null;
  }

  /// "HACCP, 유기농" → ["HACCP", "유기농"], without blanks or duplicates.
  static List<String> parseCertifications(String? value) {
    final seen = <String>{};
    return [
      for (final part in (value ?? "").split(RegExp(r"[,\n]")))
        if (part.trim().isNotEmpty && seen.add(part.trim())) part.trim(),
    ];
  }
}
