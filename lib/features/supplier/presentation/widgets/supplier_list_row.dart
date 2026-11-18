import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";
import "supplier_source_badge.dart";

/// 거래처 목록의 카드 한 장: 이름(17/700) · 출처 라벨 · 취급 품목 칩 · 위치.
/// 테두리 1px, 모서리 8. 고른 카드는 주황 2px.
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
    const muted = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);
    return Semantics(
      selected: selected,
      button: true,
      label: "${supplier.name} 거래처",
      child: LdsFocusRing(
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LdsRadius.table),
            side: selected
                ? const BorderSide(color: LdsColors.primary, width: 2)
                : const BorderSide(color: LdsColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: LdsColors.canvas,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                selected ? 15 : 16,
                selected ? 13 : 14,
                selected ? 15 : 16,
                selected ? 13 : 14,
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
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: LdsColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SupplierSourceBadge(supplier.sourceType),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Text("취급 품목 미등록", style: muted)
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: LdsColors.mutedStrong,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            supplier.location ?? "위치 미확인",
                            ?supplier.contactEmail,
                          ].join(" · "),
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 취급 품목 칩: 높이 28, 모서리 4, 바탕 `#F9FAFB`.
class _ItemChip extends StatelessWidget {
  const _ItemChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: LdsColors.canvas,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.button),
    ),
    // widthFactor 1: 글자 폭만큼만(Container.alignment는 폭을 꽉 채움).
    child: Center(
      widthFactor: 1,
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: LdsColors.title),
      ),
    ),
  );
}
