import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../domain/supplier.dart";

class SupplierSourceBadge extends StatelessWidget {
  const SupplierSourceBadge(this.sourceType, {super.key});
  final SupplierSourceType sourceType;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (sourceType) {
      SupplierSourceType.registered => (
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
        Icons.verified_outlined,
      ),
      SupplierSourceType.verifiedWeb => (
        const Color(0xFF2F5E8C),
        const Color(0xFFE6EEF6),
        Icons.language,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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
