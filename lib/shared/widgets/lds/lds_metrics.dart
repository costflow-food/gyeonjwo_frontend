/// 모서리 (`docs/design-ssot.md` 1장 끝, 4장, 7.4, 8.1, 9.0).
abstract final class LdsRadius {
  /// 버튼 small·medium, 라벨(Tag), 모달 닫기 버튼.
  static const double button = 4;

  /// 버튼 large(로그인·권한·연결).
  static const double buttonLarge = 6;

  /// 아이콘 버튼 medium (7.4.4).
  static const double iconButton = 8;

  /// 숫자 배지(높이의 절반).
  static const double badge = 10;

  /// 표 바깥 틀 (9.0).
  static const double table = 8;

  /// 패널·카드.
  static const double panel = 12;

  /// 모달.
  static const double dialog = 16;
}

/// 자주 쓰는 간격 (SSOT 7.4, 7.11, 9.0).
abstract final class LdsSpace {
  /// 버튼 아이콘과 글자 사이 (small은 [iconGapSmall]).
  static const double iconGap = 8;
  static const double iconGapSmall = 4;

  /// 표 칸 좌우 여백 (9.0).
  static const double tableCellX = 16;

  /// 이름표 칸과 값 사이 (7.11).
  static const double labelValueGap = 16;
}

abstract final class LdsText {
  /// 목록 위 조작 단추(필터·정렬·기간, outlinedPlain)의 글자 크기.
  /// Invoices·Suppliers가 같은 값을 씁니다.
  static const double control = 14;
}
