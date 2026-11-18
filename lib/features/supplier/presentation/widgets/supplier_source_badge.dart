import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/supplier.dart";

class SupplierSourceBadge extends StatelessWidget {
  const SupplierSourceBadge(this.sourceType, {super.key, this.compact = false});
  final SupplierSourceType sourceType;
  final bool compact;
  @override
  Widget build(BuildContext context) => SupplierStateTag(
    fixedWidth: compact,
    label: sourceType.label,
    background: sourceType == SupplierSourceType.registered
        ? const Color(0xFFFFDFCC)
        : const Color(0xFFFFA066),
    foreground: sourceType == SupplierSourceType.registered
        ? LdsColors.primaryText
        : LdsColors.ink,
  );
}

class SupplierStateTag extends StatelessWidget {
  const SupplierStateTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.fixedWidth = false,
  });
  final String label;
  final Color background, foreground;
  final bool fixedWidth;
  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    width: fixedWidth ? 64 : null,
    constraints: const BoxConstraints(minWidth: 64),
    padding: EdgeInsets.symmetric(horizontal: fixedWidth ? 0 : 8),

    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    ),
  );
}
