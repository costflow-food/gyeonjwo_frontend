import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../domain/supplier.dart";

/// How the supplier reached the reference data. Web candidates never show here.
class SupplierSourceBadge extends StatelessWidget {
  const SupplierSourceBadge(this.sourceType, {super.key});
  final SupplierSourceType sourceType;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (sourceType) {
      SupplierSourceType.registered => (
        const Color(0xFF4B9138),
        const Color(0xFFE7F5E1),
        Icons.verified_outlined,
      ),
      SupplierSourceType.verifiedWeb => (
        const Color(0xFF347BC8),
        const Color(0xFFDCF2FD),
        Icons.language,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            sourceType.label,
            style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
          ),
        ],
      ),
    );
  }
}
