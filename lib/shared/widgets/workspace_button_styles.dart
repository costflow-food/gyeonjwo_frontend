import 'package:flutter/material.dart';

import '../app_font_sizes.dart';
import '../workspace_colors.dart';

/// Shared appearance; each button keeps its own disabled and busy behavior.
abstract final class WorkspaceButtonStyles {
  static final filled = FilledButton.styleFrom(
    backgroundColor: ink,
    foregroundColor: Colors.white,
    disabledBackgroundColor: line,
    disabledForegroundColor: muted,
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    textStyle: const TextStyle(
      fontSize: AppFontSizes.button,
      fontWeight: FontWeight.w600,
    ),
  );

  static final outlined = OutlinedButton.styleFrom(
    foregroundColor: ink,
    disabledForegroundColor: muted,
    side: const BorderSide(color: Color(0xFFAFB3BA)),
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    textStyle: const TextStyle(
      fontSize: AppFontSizes.button,
      fontWeight: FontWeight.w600,
    ),
  );

  static final text = TextButton.styleFrom(
    foregroundColor: ink,
    textStyle: const TextStyle(fontSize: AppFontSizes.button),
  );

  static final segmented = ButtonStyle(
    foregroundColor: const WidgetStatePropertyAll(ink),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? blush : Colors.transparent,
    ),
    side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFAFB3BA))),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: AppFontSizes.secondary),
    ),
  );
}
