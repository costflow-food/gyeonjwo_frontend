import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";

/// 거래처 입력칸 = LDS 입력칸(7.14b): 이름표는 칸 위, 검사에 걸리면 칸 아래
/// 빨간 안내.
class SupplierFormField extends StatelessWidget {
  const SupplierFormField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final String label;
  final bool required;
  final String? hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => LdsTextFormField(
    controller: controller,
    label: label,
    required: required,
    hintText: hint,
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    autofocus: autofocus,
  );
}
