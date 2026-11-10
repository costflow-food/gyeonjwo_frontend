import 'package:flutter/material.dart';

import '../app_font_sizes.dart';
import '../workspace_colors.dart';

/// Shared appearance; each button keeps its own disabled and busy behavior.
abstract final class WorkspaceButtonStyles {
  static ButtonStyle filled(BuildContext context) => FilledButton.styleFrom(
    backgroundColor: context.palette.accent,
    foregroundColor: context.palette.onAccent,
    disabledBackgroundColor: context.palette.line,
    disabledForegroundColor: context.palette.muted,
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(
      fontSize: AppFontSizes.button,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle outlined(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: context.palette.accentText,
    disabledForegroundColor: context.palette.muted,
    side: BorderSide(color: context.palette.accentText),
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(
      fontSize: AppFontSizes.button,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle text(BuildContext context) => TextButton.styleFrom(
    foregroundColor: context.palette.accentText,
    textStyle: const TextStyle(fontSize: AppFontSizes.button),
  );

  static ButtonStyle segmented(BuildContext context) => ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(context.palette.ink),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? context.palette.blush
          : Colors.transparent,
    ),
    side: WidgetStatePropertyAll(BorderSide(color: context.palette.line)),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: AppFontSizes.secondary),
    ),
  );
}
