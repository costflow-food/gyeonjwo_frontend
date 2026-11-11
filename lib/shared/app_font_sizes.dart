/// 글자 크기만 관리합니다. 단위는 Flutter 논리 픽셀이며 사용자 글자 배율은 별도로 적용됩니다.
abstract final class AppFontSizes {
  // 본문과 보조 설명. 같은 역할은 여러 화면에서 함께 바뀝니다.
  static const double body = 14;
  static const double bodyLarge = 15;
  static const double secondary = 13;
  static const double caption = 12;
  static const double captionSmall = 11;

  // 버튼. 버튼만 바꾸려면 여기서 조절하세요.
  static const double button = body;
  static const double buttonSmall = secondary;
  static const double buttonLarge = bodyLarge;
  static const double navigation = 14;

  // 제목.
  static const double pageTitle = 32;
  static const double heading = 24;
  static const double sectionTitle = 22;
  static const double cardTitle = 18;
  static const double cardTitleLarge = 24;
  static const double documentTitle = 17;
  static const double dialogTitle = 22;
  static const double dialogTitleSmall = 20;

  // 숫자 강조: 요약 지표 / 카드 금액 / 단가 / 요청 건수.
  static const double number = 32;
  static const double numberSmall = 24;
  static const double numberLarge = 36;
  static const double count = 40;

  // 로고는 금액 숫자와 별도로 조절합니다.
  static const double brand = 30;
}
