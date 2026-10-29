import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";

class SupplierSectionTitle extends StatelessWidget {
  const SupplierSectionTitle(
    this.text, {
    super.key,
    this.trailing,
    this.large = false,
  });

  final String text;
  final Widget? trailing;

  /// Dialog sections use the larger size; the detail panel uses the smaller one.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: large
                  ? AppFontSizes.documentTitle
                  : AppFontSizes.bodyLarge,
              fontWeight: large ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
