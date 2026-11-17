import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

class SupplierFormField extends StatelessWidget {
  const SupplierFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.readOnly = false,
    this.helper,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;

  /// Shown but not editable (the server does not accept this value).
  final bool readOnly;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: !readOnly,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: AppFontSizes.body),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        labelStyle: const TextStyle(fontSize: AppFontSizes.body),
        hintStyle: TextStyle(
          fontSize: AppFontSizes.body,
          color: context.palette.muted,
        ),
        isDense: true,
        filled: true,
        fillColor: context.palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(
            color: context.palette.muted.withValues(alpha: .45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: context.palette.ink),
        ),
      ),
    );
  }
}
