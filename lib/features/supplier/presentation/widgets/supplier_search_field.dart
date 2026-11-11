import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

class SupplierSearchField extends StatelessWidget {
  const SupplierSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: AppFontSizes.body),
        decoration: InputDecoration(
          hintText: "업체명, 품목, 담당자, 지역 검색",
          hintStyle: TextStyle(
            fontSize: AppFontSizes.body,
            color: context.palette.muted,
          ),
          prefixIcon: const Icon(Icons.search, size: 19),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: "검색 지우기",
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged("");
                  },
                ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
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
      ),
    );
  }
}
