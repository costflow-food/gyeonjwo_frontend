import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// Label and value. A missing value reads "미확인" instead of a blank.
class SupplierFact extends StatelessWidget {
  const SupplierFact(this.label, this.value, {super.key, this.width = 180});

  final String label;
  final String? value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final missing = value == null;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.caption,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value ?? "미확인",
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: missing ? muted : ink,
              fontWeight: missing ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
