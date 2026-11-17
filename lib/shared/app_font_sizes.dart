/// 글자 크기만 관리합니다. 단위는 Flutter 논리 픽셀이며 사용자 글자 배율은 별도로 적용됩니다.
/// 기준: `docs/design-ssot.md` 2.1 크기 단계(12/13/14/15/17/20/24/48, 모달 제목 21). 12 미만은 쓰지 않습니다.
abstract final class AppFontSizes {
  // 본문과 보조 설명. 같은 역할은 여러 화면에서 함께 바뀝니다.
  static const double body = 15;
  static const double bodyLarge = 15;
  static const double secondary = 13;
  static const double caption = 12;
  static const double captionSmall = 12;

  // 버튼. 본문과 따로 움직이도록 숫자로 둡니다.
  static const double button = 15;
  static const double buttonSmall = 13;
  static const double buttonLarge = 15;
  static const double navigation = 15;

  // 제목.
  static const double pageTitle = 24;
  static const double heading = 20;
  static const double sectionTitle = 20;
  static const double cardTitle = 17;
  static const double cardTitleLarge = 20;
  static const double documentTitle = 17;
  static const double dialogTitle = 21;
  static const double dialogTitleSmall = 17;

  // 숫자 강조: 요약 지표 / 카드 금액 / 단가 / 요청 건수.
  static const double number = 28;
  static const double numberSmall = 20;
  static const double numberLarge = 32;
  static const double count = 48;

  // 로고는 금액 숫자와 별도로 조절합니다.
  static const double brand = 24;
}
