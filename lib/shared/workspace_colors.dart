import 'package:flutter/material.dart';

/// 오류·멈춤. 어떤 테마에서도 포인트 색과 구분되도록 고정합니다.
const danger = Color(0xFFC8102E);
const dangerTint = Color(0xFFFBE9EB);

/// 화면에서 쓰는 테마 색. 판은 연하게 두고, 진한 색은 포인트(주 버튼·선택·강조 카드)에만 씁니다.
/// 위젯에서는 `context.palette.accent`처럼 꺼내 씁니다.
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
    this.gold = const Color(0xFFCBA258),
    this.surface = Colors.white,
    this.brightness = Brightness.light,
    this._deep,
  });

  /// 저장할 때 쓰는 값과 설정 화면에 보이는 이름.
  final String id, name;

  /// 글자와 진한 카드(구매안·인상 요청)의 바탕.
  final Color ink;

  /// 보조 글자.
  final Color muted;

  /// 선과 칸 테두리.
  final Color line;

  /// 포인트: 주 버튼, 선택한 탭·줄, 진행 표시.
  final Color accent;

  /// 흰 바탕 위에 포인트 색으로 쓰는 글자·아이콘·테두리. 밝은 포인트 색에서는 더 진합니다.
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

  /// 카드·입력칸·선택한 줄의 바탕. 라이트에서는 흰색입니다.
  final Color surface;

  /// 라이트/다크.
  final Brightness brightness;

  /// 진한 카드(구매안·인상 요청·툴팁)의 바탕. 라이트에서는 [ink]와 같습니다.
  Color get deep => _deep ?? ink;
  final Color? _deep;

  bool get isDark => brightness == Brightness.dark;

  static const houseGreen = WorkspacePalette(
    id: 'house-green',
    name: '하우스 그린',
    ink: Color(0xFF1E3932),
    muted: Color(0xFF4F6862),
    line: Color(0xFFE3ECE7),
    accent: Color(0xFF00704A),
    accentText: Color(0xFF00704A),
    onAccent: Colors.white,
    canvas: Color(0xFFF2F0EB),
    blush: Color(0xFFE3F0EA),
    frame: Color(0xFFDCE7E1),
    panel: Color(0xFFF8FBF9),
    deepLight: Color(0xFF2C5A4D),
    onDeepMuted: Color(0xFFC3DAD1),
  );

  static const houseBlue = WorkspacePalette(
    id: 'house-blue',
    name: '하우스 블루',
    ink: Color(0xFF112D4E),
    muted: Color(0xFF4F647C),
    line: Color(0xFFE0E4E8),
    accent: Color(0xFF3F72AF),
    accentText: Color(0xFF3F72AF),
    onAccent: Colors.white,
    canvas: Color(0xFFF0F2F6),
    blush: Color(0xFFEAEFF6),
    frame: Color(0xFFD9E0E9),
    panel: Color(0xFFF9FBFD),
    deepLight: Color(0xFF2E4663),
    onDeepMuted: Color(0xFFC5D9F1),
  );

  static const sandSage = WorkspacePalette(
    id: 'sand-sage',
    name: '샌드 세이지',
    ink: Color(0xFF3A332B),
    muted: Color(0xFF655F59),
    line: Color(0xFFE5E4E3),
    accent: Color(0xFF9C4A2A),
    accentText: Color(0xFF9C4A2A),
    onAccent: Colors.white,
    canvas: Color(0xFFF2EFE6),
    blush: Color(0xFFF4EBE8),
    frame: Color(0xFFE6DAD6),
    panel: Color(0xFFFCFAF9),
    deepLight: Color(0xFF524B44),
    onDeepMuted: Color(0xFFF0D0BF),
  );

  static const charcoalAmber = WorkspacePalette(
    id: 'charcoal-amber',
    name: '차콜 앰버',
    ink: Color(0xFF393E46),
    muted: Color(0xFF656A70),
    line: Color(0xFFE5E6E7),
    accent: Color(0xFFF8B500),
    accentText: Color(0xFF856E2A),
    onAccent: Color(0xFF393E46),
    canvas: Color(0xFFF2F2F0),
    blush: Color(0xFFFEF7E3),
    frame: Color(0xFFF3E9D0),
    panel: Color(0xFFFFFDF7),
    deepLight: Color(0xFF51555C),
    onDeepMuted: Color(0xFFFFEDBD),
  );

  static const burgundyRed = WorkspacePalette(
    id: 'burgundy-red',
    name: '버건디 레드',
    ink: Color(0xFF1D1616),
    muted: Color(0xFF615C5C),
    line: Color(0xFFE2E1E1),
    accent: Color(0xFF8E1616),
    accentText: Color(0xFF8E1616),
    onAccent: Colors.white,
    canvas: Color(0xFFF2EFEE),
    blush: Color(0xFFF3E5E5),
    frame: Color(0xFFE4D3D3),
    panel: Color(0xFFFCF8F8),
    deepLight: Color(0xFF383232),
    onDeepMuted: Color(0xFFEFB3B3),
  );

  static const deepOcean = WorkspacePalette(
    id: 'deep-ocean',
    name: '딥 오션',
    ink: Color(0xFF071B2B),
    muted: Color(0xFF515F6B),
    line: Color(0xFFDFE1E3),
    accent: Color(0xFF167D8D),
    accentText: Color(0xFF167B8B),
    onAccent: Colors.white,
    canvas: Color(0xFFEEF2F2),
    blush: Color(0xFFE5F1F2),
    frame: Color(0xFFD3E2E4),
    panel: Color(0xFFF8FBFC),
    deepLight: Color(0xFF253644),
    onDeepMuted: Color(0xFFB2E2E8),
  );

  static const slateGray = WorkspacePalette(
    id: 'slate-gray',
    name: '슬레이트 그레이',
    ink: Color(0xFF2B323C),
    muted: Color(0xFF5B6068),
    line: Color(0xFFE3E4E6),
    accent: Color(0xFF495464),
    accentText: Color(0xFF495464),
    onAccent: Colors.white,
    canvas: Color(0xFFF4F4F2),
    blush: Color(0xFFEBECEE),
    frame: Color(0xFFDADCDE),
    panel: Color(0xFFFAFAFA),
    deepLight: Color(0xFF444B53),
    onDeepMuted: Color(0xFFD2D6DF),
  );

  static const greenGradient = WorkspacePalette(
    id: 'green-gradient',
    name: '그린 그라데이션',
    ink: Color(0xFF12352E),
    muted: Color(0xFF4D6762),
    line: Color(0xFFE0E5E4),
    accent: Color(0xFF1F6F5F),
    accentText: Color(0xFF1F6F5F),
    onAccent: Colors.white,
    canvas: Color(0xFFEEF1EF),
    blush: Color(0xFFE6EFED),
    frame: Color(0xFFD4E0DD),
    panel: Color(0xFFF8FBFA),
    deepLight: Color(0xFF2E4D47),
    onDeepMuted: Color(0xFFC5ECD5),
  );

  static const mintRose = WorkspacePalette(
    id: 'mint-rose',
    name: '민트 로즈',
    ink: Color(0xFF1F3B34),
    muted: Color(0xFF586D68),
    line: Color(0xFFE2E6E5),
    accent: Color(0xFFDC9B9B),
    accentText: Color(0xFF826D6A),
    onAccent: Color(0xFF1F3B34),
    canvas: Color(0xFFF6F4E8),
    blush: Color(0xFFFBF4F4),
    frame: Color(0xFFEFE6E6),
    panel: Color(0xFFFEFCFC),
    deepLight: Color(0xFF3A534C),
    onDeepMuted: Color(0xFFE6F3ED),
  );

  static const orangeWhite = WorkspacePalette(
    id: 'orange-white',
    name: '오렌지 화이트',
    ink: Color(0xFF1A1A1A),
    muted: Color(0xFF5F5F5F),
    line: Color(0xFFE1E1E1),
    accent: Color(0xFFFF8C00),
    accentText: Color(0xFFA35E0A),
    onAccent: Color(0xFF1A1A1A),
    canvas: Color(0xFFF2F1EE),
    blush: Color(0xFFFFF2E3),
    frame: Color(0xFFF4E4D0),
    panel: Color(0xFFFFFCF7),
    deepLight: Color(0xFF353535),
    onDeepMuted: Color(0xFFFFE1BE),
  );

  static const greenWhite = WorkspacePalette(
    id: 'green-white',
    name: '그린 화이트',
    ink: Color(0xFF111814),
    muted: Color(0xFF585D5A),
    line: Color(0xFFE0E1E0),
    accent: Color(0xFF00DC64),
    accentText: Color(0xFF088440),
    onAccent: Color(0xFF111814),
    canvas: Color(0xFFF0F2F0),
    blush: Color(0xFFE3FBEE),
    frame: Color(0xFFD0EFDE),
    panel: Color(0xFFF7FEFA),
    deepLight: Color(0xFF2E3430),
    onDeepMuted: Color(0xFFCBF9DF),
  );

  static const blueViolet = WorkspacePalette(
    id: 'blue-violet',
    name: '블루 바이올렛',
    ink: Color(0xFF1F2160),
    muted: Color(0xFF5D5F8C),
    line: Color(0xFFE2E2EA),
    accent: Color(0xFF5865F2),
    accentText: Color(0xFF5460E7),
    onAccent: Colors.white,
    canvas: Color(0xFFF0F1F7),
    blush: Color(0xFFEDEEFE),
    frame: Color(0xFFDCDEF2),
    panel: Color(0xFFFAFAFF),
    deepLight: Color(0xFF3A3C73),
    onDeepMuted: Color(0xFFD1D5FF),
  );

  /// 설정 화면에 보이는 순서. 첫 번째가 기본값입니다.
  static const all = [
    houseGreen,
    houseBlue,
    sandSage,
    charcoalAmber,
    burgundyRed,
    deepOcean,
    slateGray,
    greenGradient,
    mintRose,
    orangeWhite,
    greenWhite,
    blueViolet,
  ];

  static WorkspacePalette byId(String? id) =>
      all.where((palette) => palette.id == id).firstOrNull ?? houseGreen;

  /// 진한 카드·패널 그림자. 라이트에서는 글자색을 옅게, 다크에서는 검정을 섞습니다.
  Color shadow(double opacity) =>
      (isDark ? Colors.black : ink).withValues(alpha: opacity);

  /// 이 테마의 다크 버전. 글자색의 색조로 어두운 판을 만들고, 포인트 색은 어두운 바탕에서
  /// 보이도록 밝힙니다.
  WorkspacePalette toDark() {
    if (isDark) return this;
    final hue = HSLColor.fromColor(ink).hue;
    final tint = HSLColor.fromColor(ink).saturation.clamp(0.0, .35);
    Color tone(double lightness, [double? saturation]) =>
        HSLColor.fromAHSL(1, hue, saturation ?? tint, lightness).toColor();
    final point = HSLColor.fromColor(accent);
    final fill = point
        .withLightness(point.lightness.clamp(.45, .62))
        .withSaturation(point.saturation.clamp(0.0, .75))
        .toColor();
    final pointText = point
        .withLightness(point.lightness.clamp(.68, .8))
        .withSaturation(point.saturation.clamp(0.0, .8))
        .toColor();
    return WorkspacePalette(
      id: id,
      name: name,
      brightness: Brightness.dark,
      ink: tone(.92, tint * .5),
      muted: tone(.68, tint * .6),
      line: tone(.24),
      accent: fill,
      accentText: pointText,
      onAccent: fill.computeLuminance() > .35 ? tone(.08) : Colors.white,
      canvas: tone(.09),
      blush: HSLColor.fromAHSL(
        1,
        point.hue,
        point.saturation.clamp(0.0, .45),
        .2,
      ).toColor(),
      frame: tone(.07),
      panel: tone(.11),
      surface: tone(.15),
      deep: tone(.2),
      deepLight: tone(.3),
      onDeepMuted: onDeepMuted,
      gold: gold,
    );
  }

  @override
  WorkspacePalette copyWith() => this;

  @override
  WorkspacePalette lerp(WorkspacePalette? other, double t) =>
      other == null || t < .5 ? this : other;
}

extension WorkspacePaletteContext on BuildContext {
  WorkspacePalette get palette =>
      Theme.of(this).extension<WorkspacePalette>() ??
      WorkspacePalette.houseGreen;
}
