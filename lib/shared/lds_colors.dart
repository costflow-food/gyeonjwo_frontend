import 'package:flutter/material.dart';

/// 팔레트(`WorkspacePalette`)에 없는 LDS 색 (`docs/design-ssot.md` 1장·4장·7.16).
/// 화면 위젯에서 SSOT 값을 그대로 쓸 때 가져다 씁니다.
abstract final class LdsColors {
  static const primary = Color(0xFFFF6000);
  static const primaryHover = Color(0xFFCC4D00);
  static const primarySoft = Color(0xFFFFEFE5);
  static const primaryLight = Color(0xFFFFBF99); // 진행 단계 남은 구간·테두리
  static const primaryRow = Color(0xFFFFF7F2); // 최신·추천 줄
  static const primaryText = Color(0xFF993A00); // 연주황 바탕 위 글자
  static const selectedRow = Color(0xFFFFF4EC); // 고른 업무 행
  static const ink = Color(0xFF191F28);
  static const title = Color(0xFF333D4B);
  static const label = Color(0xFF4E5968); // 표 이름표·머리
  static const muted = Color(0xFF6B7583);
  static const mutedStrong = Color(0xFF5E6876); // 연회색 바탕 위 보조 글자
  static const outline = Color(0xFF8A95A0);
  static const borderStrong = Color(0xFFD1D6DC);
  static const line = Color(0xFFE5E7EA);
  static const lineSoft = Color(0xFFF3F4F6);
  static const canvas = Color(0xFFF9FAFB);
  static const disabled = Color(0xFFB1B8C0);
  static const badgeNeutralBg = Color(0xFFF2F4F6);
  static const error = Color(0xFFF64C4C);
  static const errorBg = Color(0xFFFDF0F3);
  static const errorText = Color(0xFFC8202F); // 연한 바탕 위 오류 글자(4.5:1)
  static const info = Color(0xFF3D94FF);
  static const infoBg = Color(0xFFE5F5FF);
  static const infoText = Color(0xFF1B64DA); // 연한 바탕 위 안내 글자(4.5:1)
  static const warning = Color(0xFFFFB700);
  static const warningBg = Color(0xFFFFF8E4);
  static const warningText = Color(0xFF745300);
  static const success = Color(0xFF79B116);
  static const successBg = Color(0xFFF2FDE3);
  static const successText = Color(0xFF4F7A0C); // 검토 카드 접근성 기준
  static const cautionText = Color(0xFF8A6200);
  static const priceUp = Color(0xFFE42939);
  static const priceDown = Color(0xFF1B64DA);
  static const overlay = Color(0x73191F28); // rgba(25,31,40,.45)
}
