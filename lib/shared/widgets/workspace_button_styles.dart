import 'package:flutter/material.dart';

import '../app_font_sizes.dart';
import '../lds_colors.dart';
import '../workspace_colors.dart';

/// 버튼 모양 (`docs/design-ssot.md` 7.4 medium): 높이 36, 좌우 12, 모서리 4, 글자 15/700.
abstract final class WorkspaceButtonStyles {
  static const _size = Size(0, 36);
  static const _padding = EdgeInsets.symmetric(horizontal: 12);
  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );
  static const _label = TextStyle(
    fontFamily: 'NanumGothic',
    fontSize: AppFontSizes.button,
    fontWeight: FontWeight.w700,
  );

  static ButtonStyle filled(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: context.palette.accent,
        foregroundColor: context.palette.onAccent,
        disabledBackgroundColor: LdsColors.lineSoft,
        disabledForegroundColor: LdsColors.disabled,
        elevation: 0,
        visualDensity: VisualDensity.standard,
        minimumSize: _size,
        padding: _padding,
        shape: _shape,
        textStyle: _label,
      ).copyWith(
        // hover는 겹침 색 대신 바탕을 #CC4D00으로 바꿉니다.
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? LdsColors.lineSoft
              : states.contains(WidgetState.hovered)
              ? LdsColors.primaryHover
              : context.palette.accent,
        ),
      );

  static ButtonStyle outlined(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: context.palette.accentText,
        disabledForegroundColor: LdsColors.disabled,
        elevation: 0,
        visualDensity: VisualDensity.standard,
        minimumSize: _size,
        padding: _padding,
        shape: _shape,
        textStyle: _label,
      ).copyWith(
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? LdsColors.line
                : LdsColors.borderStrong,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) &&
                  !states.contains(WidgetState.disabled)
              ? LdsColors.canvas
              : null,
        ),
      );

  static ButtonStyle text(BuildContext context) => TextButton.styleFrom(
    foregroundColor: LdsColors.title,
    disabledForegroundColor: LdsColors.disabled,
    visualDensity: VisualDensity.standard,
    minimumSize: _size,
    padding: _padding,
    shape: _shape,
    textStyle: _label,
  );

  static ButtonStyle segmented(BuildContext context) => ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(context.palette.ink),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? context.palette.blush
          : Colors.transparent,
    ),
    side: WidgetStatePropertyAll(BorderSide(color: context.palette.line)),
    shape: const WidgetStatePropertyAll(_shape),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: AppFontSizes.secondary),
    ),
  );
}
