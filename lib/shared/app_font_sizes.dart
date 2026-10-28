/// 글자 크기만 관리합니다. 단위는 Flutter 논리 픽셀이며 사용자 글자 배율은 별도로 적용됩니다.
/// 기존 화면의 크기를 유지했습니다. 아이콘·여백·반응형 기준값은 여기에 포함하지 않습니다.
abstract final class AppFontSizes {
  // 본문과 보조 설명. 같은 역할은 여러 화면에서 함께 바뀝니다.
  static const double body = 12;
  static const double bodyLarge = 13;
  static const double secondary = 11;
  static const double caption = 10;
  static const double captionSmall = 9;

  // 버튼은 기존 12 / 11 / 13 크기를 구분합니다. 버튼만 바꾸려면 여기서 조절하세요.
  static const double button = body;
  static const double buttonSmall = secondary;
  static const double buttonLarge = bodyLarge;
  static const double navigation = 14;

  // 제목. 기존에 조금씩 달랐던 크기를 보존한 공통 크기 단계입니다.
  static const double pageTitle = 28;
  static const double heading = 21;
  static const double sectionTitle = 19;
  static const double cardTitle = 17;
  static const double cardTitleLarge = 23;
  static const double documentTitle = 16;
  static const double dialogTitle = 20;
  static const double dialogTitleSmall = 18;

  // 숫자 강조: 요약 지표 / 카드 금액 / 단가 / 요청 건수.
  static const double number = 28;
  static const double numberSmall = 22;
  static const double numberLarge = 30;
  static const double count = 34;

  // 로고는 금액 숫자와 별도로 조절합니다.
  static const double brand = 30;
}
