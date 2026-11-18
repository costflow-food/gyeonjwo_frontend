import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';

enum LdsTagSize {
  /// 높이 24 · 좌우 8 · 13px.
  small(height: 24, fontSize: 13),

  /// 높이 28 · 좌우 8 · 15px.
  medium(height: 28, fontSize: 15);

  const LdsTagSize({required this.height, required this.fontSize});

  final double height, fontSize;
}

enum LdsTagStyle {
  /// 색 바탕, 흰 글자.
  solid,

  /// 1px 색 테두리, 색 글자.
  outline,

  /// 연한 바탕, 색 글자 (4.1 weak 색표).
  weak,
}

/// 라벨 색조 (`docs/design-ssot.md` 4.1 weak 색표).
enum LdsTagTone {
  enabled(color: LdsColors.primary, soft: LdsColors.primarySoft),
  error(color: LdsColors.error, soft: LdsColors.errorBg),
  progressing(color: LdsColors.info, soft: LdsColors.infoBg),
  warning(color: LdsColors.warning, soft: LdsColors.warningBg),
  success(color: LdsColors.success, soft: LdsColors.successBg);

  const LdsTagTone({required this.color, required this.soft});

  final Color color, soft;
}

/// 라벨 — LIKELION Tag (`docs/design-ssot.md` 4.1).
///
/// 모서리 4, 아이콘 16, 아이콘과 글자 사이 4, 글자 400.
/// 대비를 높여야 하는 곳(검토 카드 7.16)은 [foreground]로 글자색만 바꿉니다.
class LdsTag extends StatelessWidget {
  const LdsTag(
    this.label, {
    super.key,
    this.tone = LdsTagTone.enabled,
    this.style = LdsTagStyle.weak,
    this.size = LdsTagSize.small,
    this.icon,
    this.foreground,
  });

  final String label;
  final LdsTagTone tone;
  final LdsTagStyle style;
  final LdsTagSize size;
  final IconData? icon;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final (background, ink, border) = switch (style) {
      LdsTagStyle.solid => (tone.color, Colors.white, null),
      LdsTagStyle.outline => (Colors.transparent, tone.color, tone.color),
      LdsTagStyle.weak => (tone.soft, tone.color, null),
    };
    final text = foreground ?? ink;
    return Container(
      height: size.height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(LdsRadius.button),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: size.fontSize,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

enum LdsBadgeTone {
  /// `#FF6000` + 흰 글자: 확인 필요·알림.
  primary(background: LdsColors.primary, foreground: Colors.white),

  /// `#191F28` + 흰 글자: 선택된 탭.
  dark(background: LdsColors.ink, foreground: Colors.white),

  /// `#F2F4F6` + `#6B7583`: 그 외.
  neutral(background: LdsColors.badgeNeutralBg, foreground: LdsColors.muted);

  const LdsBadgeTone({required this.background, required this.foreground});

  final Color background, foreground;
}

/// 숫자 배지 — LIKELION Badge (`docs/design-ssot.md` 4.2).
///
/// 높이 20 · 최소 폭 20 · 좌우 6.5 · 모서리 10. 한 자리는 원, 두 자리부터 알약형.
/// 글자 13px/700, 고정폭 숫자. 왼쪽 메뉴에는 쓰지 않습니다.
class LdsBadge extends StatelessWidget {
  const LdsBadge(this.count, {super.key, this.tone = LdsBadgeTone.neutral});

  final int count;
  final LdsBadgeTone tone;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    // 한 자리는 20×20 원, 두 자리부터 좌우 6.5 알약형.
    width: count.abs() < 10 ? 20 : null,
    constraints: const BoxConstraints(minWidth: 20),
    padding: count.abs() < 10
        ? null
        : const EdgeInsets.symmetric(horizontal: 6.5),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(LdsRadius.badge),
    ),
    // widthFactor 1: 글자 폭만큼만 차지합니다(Container.alignment는 폭을 꽉 채움).
    child: Center(
      widthFactor: 1,
      child: Text(
        '$count',
        maxLines: 1,
        // 배지 숫자는 사용자 글자 배율로 커지면 20 높이를 넘으므로 고정합니다.
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
          color: tone.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
