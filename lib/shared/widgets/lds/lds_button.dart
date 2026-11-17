import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';

enum LdsButtonVariant {
  /// 주황 바탕 흰 글자 (`#FF6000`, hover `#CC4D00`).
  filled,

  /// 1px `#D1D6DC` 테두리, 주황 글자.
  outlined,

  /// 1px `#D1D6DC` 테두리, 중립 글자 `#333D4B`.
  outlinedNeutral,
}

enum LdsButtonSize {
  /// 28 · 좌우 10 · 13px.
  small(height: 28, paddingX: 10, fontSize: 13, radius: LdsRadius.button),

  /// 36 · 좌우 12 · 15px/700 (기본).
  medium(height: 36, paddingX: 12, fontSize: 15, radius: LdsRadius.button),

  /// 48 · 좌우 16 · 15px/700 · 모서리 6 (로그인·권한·연결).
  large(height: 48, paddingX: 16, fontSize: 15, radius: LdsRadius.buttonLarge);

  const LdsButtonSize({
    required this.height,
    required this.paddingX,
    required this.fontSize,
    required this.radius,
  });

  final double height, paddingX, fontSize, radius;
}

/// LDS 버튼 (`docs/design-ssot.md` 7.4).
///
/// [loading]이면 글자를 숨기고 20px 원을 보이되 버튼 폭은 그대로 둡니다(7.4.3).
/// 불러오는 동안에는 눌리지 않습니다.
class LdsButton extends StatelessWidget {
  const LdsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LdsButtonVariant.filled,
    this.size = LdsButtonSize.medium,
    this.icon,
    this.loading = false,
  });

  final String label;

  /// null이면 비활성입니다.
  final VoidCallback? onPressed;
  final LdsButtonVariant variant;
  final LdsButtonSize size;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final filled = variant == LdsButtonVariant.filled;
    final foreground = switch (variant) {
      LdsButtonVariant.filled => Colors.white,
      LdsButtonVariant.outlined => LdsColors.primary,
      LdsButtonVariant.outlinedNeutral => LdsColors.title,
    };
    final style = ButtonStyle(
      // 데스크톱 기본 밀도(compact)는 높이를 8 줄이므로 표준으로 고정합니다.
      visualDensity: VisualDensity.standard,
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: WidgetStatePropertyAll(Size(0, size.height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: size.paddingX),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.radius),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: size.fontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? LdsColors.disabled
            : foreground,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final disabled = states.contains(WidgetState.disabled);
        final hovered = states.contains(WidgetState.hovered);
        if (filled) {
          if (disabled) return LdsColors.lineSoft;
          return hovered ? LdsColors.primaryHover : LdsColors.primary;
        }
        return hovered && !disabled ? LdsColors.canvas : Colors.white;
      }),
      side: filled
          ? null
          : WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? LdsColors.line
                    : LdsColors.borderStrong,
              ),
            ),
      // hover는 바탕색으로만 보여 줍니다.
      overlayColor: filled
          ? const WidgetStatePropertyAll(Colors.transparent)
          : null,
    );

    final gap = size == LdsButtonSize.small
        ? LdsSpace.iconGapSmall
        : LdsSpace.iconGap;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: size == LdsButtonSize.small ? 16 : 20),
          SizedBox(width: gap),
        ],
        Text(label),
      ],
    );
    final child = Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
          visible: !loading,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: content,
        ),
        if (loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: onPressed == null ? LdsColors.disabled : foreground,
            ),
          ),
      ],
    );
    final button = filled
        ? FilledButton(style: style, onPressed: onPressed, child: child)
        : OutlinedButton(style: style, onPressed: onPressed, child: child);
    return Semantics(
      label: loading ? '$label, 불러오는 중' : null,
      child: AbsorbPointer(absorbing: loading, child: button),
    );
  }
}

/// 아이콘 버튼 medium (`docs/design-ssot.md` 7.4.4): 36px, 모서리 8, 아이콘 20, 중립 외곽선.
class LdsIconButton extends StatelessWidget {
  const LdsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;

  /// 화면 낭독기와 마우스 툴팁에 쓰는 이름.
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: OutlinedButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        fixedSize: const WidgetStatePropertyAll(Size.square(36)),
        minimumSize: const WidgetStatePropertyAll(Size.square(36)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LdsRadius.iconButton),
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? LdsColors.disabled
              : LdsColors.title,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) &&
                  !states.contains(WidgetState.disabled)
              ? LdsColors.canvas
              : Colors.white,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? LdsColors.line
                : LdsColors.borderStrong,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Icon(icon, size: 20, semanticLabel: tooltip),
    ),
  );
}
