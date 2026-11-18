import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/app_icons.dart";
import "../../../../shared/widgets/list_detail_layout.dart";
import "../../domain/supplier.dart";
import "supplier_source_badge.dart";

/// HTML v3: 48px 한 줄, 거래처 128px / 품목 / 상태 64px.
class SupplierListRow extends StatelessWidget {
  const SupplierListRow({
    super.key,
    required this.supplier,
    required this.selected,
    required this.onTap,
    this.query = "",
  });
  final SupplierSummary supplier;
  final bool selected;
  final VoidCallback onTap;
  final String query;
  @override
  Widget build(BuildContext context) {
    final items = supplier.itemNames;
    return ListSelectableRow(
      selected: selected,
      onTap: onTap,
      semanticLabel:
          "${supplier.name} 거래처, ${supplier.sourceType.label}, ${items.join(', ')}, ${supplier.location ?? ''}",
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 128,
              child: Row(
                children: [
                  const AppIconView(
                    AppIcon.suppliers,
                    size: 16,
                    color: LdsColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      supplier.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                items.isEmpty
                    ? "품목 미등록"
                    : "${items.first}${items.length > 1 ? ' 외 ${items.length - 1}' : ''}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: items.isEmpty ? LdsColors.outline : LdsColors.label,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 64,
              child: supplier.missingInfoCount > 0
                  ? SupplierMissingInfoBadge(supplier.missingInfoCount)
                  : SupplierSourceBadge(supplier.sourceType, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

class SupplierMissingInfoBadge extends StatelessWidget {
  const SupplierMissingInfoBadge(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => const SupplierStateTag(
    fixedWidth: true,
    label: "정보 부족",
    background: LdsColors.primary,
    foreground: Colors.white,
  );
}
