import 'package:flutter/material.dart';

/// 오류·멈춤 (LDS error). 포인트 색과 구분되도록 고정합니다.
const danger = Color(0xFFF64C4C);
const dangerTint = Color(0xFFFDF0F3);

/// 확인할 것이 남음. 오류는 아니어서 [danger]보다 약하게 알립니다 (SSOT 7.16 접근성 글자색).
const caution = Color(0xFF8A6200);
const cautionTint = Color(0xFFFFF8E4);

/// 화면에서 쓰는 색. LDS 주황 단일 테마이며, 판은 연하게 두고 진한 색은 포인트에만 씁니다.
/// 위젯에서는 `context.palette.accent`처럼 꺼내 씁니다. 팔레트에 없는 SSOT 색은 `lds_colors.dart`.
@immutable
class WorkspacePalette extends ThemeExtension<WorkspacePalette> {
  const WorkspacePalette({
    required this.id,
    required this.name,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.canvas,
    required this.blush,
    required this.frame,
    required this.panel,
    required this.deepLight,
    required this.onDeepMuted,
    this.gold = const Color(0xFFFF6000),
    this.surface = Colors.white,
  });

  /// 팔레트 식별자와 이름.
  final String id, name;

  /// 글자와 진한 카드(구매안·인상 요청)의 바탕.
  final Color ink;

  /// 보조 글자.
  final Color muted;

  /// 선과 칸 테두리.
  final Color line;

  /// 포인트: 주 버튼, 선택한 탭·줄, 진행 표시.
  final Color accent;

  /// 흰 바탕 위에 포인트 색으로 쓰는 글자·아이콘·테두리.
  final Color accentText;

  /// 포인트 색을 깐 곳 위의 글자.
  final Color onAccent;

  /// 앱 바깥 바탕.
  final Color canvas;

  /// 포인트를 옅게 깐 배경(선택한 줄, 안내).
  final Color blush;

  /// 사이드바·위쪽 메뉴가 놓이는 판.
  final Color frame;

  /// 가운데 작업 판.
  final Color panel;

  /// 진한 카드 그라데이션 위쪽 색과 그 위 보조 글자.
  final Color deepLight, onDeepMuted;

  /// 가장 낮은 확정 가능 구매안 강조.
  final Color gold;

  /// 카드·입력칸·선택한 줄의 바탕.
  final Color surface;

  /// 진한 바탕(툴팁·스낵바·진한 카드). [ink]와 같습니다.
  Color get deep => ink;

  /// LDS 단일 테마 (SSOT 1장).
  static const lds = WorkspacePalette(
    id: 'lds',
    name: 'LDS',
    ink: Color(0xFF191F28),
    muted: Color(0xFF6B7583),
    line: Color(0xFFE5E7EA),
    accent: Color(0xFFFF6000),
    accentText: Color(0xFFFF6000),
    onAccent: Colors.white,
    canvas: Color(0xFFF9FAFB),
    blush: Color(0xFFFFEFE5),
    frame: Colors.white,
    panel: Color(0xFFF9FAFB),
    surface: Colors.white,
    deepLight: Color(0xFF333D4B),
    onDeepMuted: Color(0xFFD1D6DC),
    // 최저 안 강조 = 주황 테두리 (SSOT 7.16).
    gold: Color(0xFFFF6000),
  );

  /// 카드·패널 그림자. 글자색을 옅게 씁니다.
  Color shadow(double opacity) => ink.withValues(alpha: opacity);

  @override
  WorkspacePalette copyWith() => this;

  @override
  WorkspacePalette lerp(WorkspacePalette? other, double t) =>
      other == null || t < .5 ? this : other;
}

extension WorkspacePaletteContext on BuildContext {
  WorkspacePalette get palette =>
      Theme.of(this).extension<WorkspacePalette>() ?? WorkspacePalette.lds;
}
