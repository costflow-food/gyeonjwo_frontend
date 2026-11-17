import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';

/// 입력칸 — LIKELION TextField (`docs/design-ssot.md` 7.14b).
///
/// 높이 36(한 줄), 1px `#D1D6DC`, 모서리 4, 초점 `#333D4B`. 이름표는 칸 위
/// 14/700 `#4E5968`, [errorText]가 있으면 칸 아래 빨간 안내(13)와 빨간 테두리.
class LdsTextField extends StatelessWidget {
  const LdsTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.required = false,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
  });

  static const height = 36.0;

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// 칸 위 이름표. [required]면 뒤에 주황 '*'.
  final String? label;
  final bool required;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;

  /// 칸 오른쪽 끝(예: 지우기 단추).
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// 1이면 높이 36 한 줄, 그 이상이면 여러 줄 칸.
  final int maxLines;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LdsRadius.button),
      borderSide: BorderSide(color: color),
    );
    final error = errorText;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      enabled: enabled,
      autofocus: autofocus,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(fontSize: 15, color: LdsColors.ink),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 15, color: LdsColors.disabled),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: LdsColors.muted),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 32),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines == 1 ? 8 : 10,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : LdsColors.lineSoft,
        border: border(LdsColors.borderStrong),
        enabledBorder: border(
          error == null ? LdsColors.borderStrong : LdsColors.error,
        ),
        focusedBorder: border(
          error == null ? LdsColors.title : LdsColors.error,
        ),
        disabledBorder: border(LdsColors.line),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: LdsColors.primary),
                  ),
              ],
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LdsColors.label,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (maxLines == 1) SizedBox(height: height, child: field) else field,
        if (error != null) ...[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: const TextStyle(fontSize: 13, color: LdsColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

/// [LdsTextField]를 `Form` 안에서 검사(validator)와 함께 씁니다. 검사에 걸리면
/// 칸 아래 빨간 안내와 빨간 테두리. 입력하면 바로 다시 검사합니다.
class LdsTextFormField extends FormField<String> {
  LdsTextFormField({
    super.key,
    required TextEditingController controller,
    String? label,
    bool required = false,
    String? hintText,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : super(
         initialValue: controller.text,
         // 값은 늘 칸의 글자에서 읽습니다(코드로 바꾼 값도 포함).
         validator: validator == null
             ? null
             : (_) => validator(controller.text),
         builder: (state) => LdsTextField(
           controller: controller,
           label: label,
           required: required,
           hintText: hintText,
           errorText: state.errorText,
           keyboardType: keyboardType,
           maxLines: maxLines,
           autofocus: autofocus,
           onChanged: (value) {
             state.didChange(value);
             onChanged?.call(value);
           },
         ),
       );
}
