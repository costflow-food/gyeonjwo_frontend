import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "supplier_source_badge.dart";

class SupplierListRow extends StatelessWidget {
  const SupplierListRow({
    super.key,
    required this.supplier,
    required this.selected,
    required this.onTap,
  });

  final SupplierSummary supplier;
  final bool selected;
  final VoidCallback onTap;

  static const _shownItems = 3;

  @override
  Widget build(BuildContext context) {
    final items = supplier.itemNames;
    final subtitle = [
      supplier.location ?? "위치 미확인",
      supplier.contactEmail ?? "이메일 미확인",
    ].join(" · ");
    return Semantics(
      selected: selected,
      button: true,
      label: "${supplier.name} 거래처",
      child: Material(
        color: selected ? blush : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
                bottom: const BorderSide(color: line),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        supplier.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppFontSizes.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SupplierSourceBadge(supplier.sourceType),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text(
                    "취급 품목 미등록",
                    style: TextStyle(
                      fontSize: AppFontSizes.secondary,
                      color: muted,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final name in items.take(_shownItems))
                        _ItemChip(name),
                      if (items.length > _shownItems)
                        _ItemChip("+${items.length - _shownItems}"),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: AppFontSizes.caption),
      ),
    );
  }
}
