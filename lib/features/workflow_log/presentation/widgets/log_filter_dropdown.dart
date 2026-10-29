import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// One filter. A null value means "전체".
class LogFilterDropdown<T> extends StatelessWidget {
  const LogFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.allowAll = true,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T option) labelOf;
  final ValueChanged<T?> onChanged;

  /// False when the filter always has a value (for example the period).
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: DropdownButtonFormField<T?>(
        // initialValue is read once; the key resets the field when the
        // filter changes from outside (for example "필터 초기화").
        key: ValueKey<Object?>(value),
        initialValue: value,
        isExpanded: true,
        onChanged: onChanged,
        style: const TextStyle(fontSize: AppFontSizes.body, color: ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: AppFontSizes.body),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: Color(0xFFB4B7BD)),
          ),
        ),
        items: [
          if (allowAll)
            DropdownMenuItem<T?>(value: null, child: const Text("전체")),
          for (final option in options)
            DropdownMenuItem<T?>(value: option, child: Text(labelOf(option))),
        ],
      ),
    );
  }
}
