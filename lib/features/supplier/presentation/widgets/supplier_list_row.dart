import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/list_detail_layout.dart";
import "../../domain/supplier.dart";
import "supplier_source_badge.dart";

/// 거래처 목록 한 줄(Tasks 목록과 같은 촘촘한 줄).
///
/// 1줄 = 업체명(15/700) + 취급 품목(13 `#6B7583`, 넘치면 말줄임) + 오른쪽
/// 출처 라벨. 2줄 = 지역 · 이메일(13 `#6B7583`). 고른 줄은 `#FFF4EC` + 왼쪽
/// 주황 3px.
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

  static const _muted = TextStyle(fontSize: 13, color: LdsColors.muted);

  @override
  Widget build(BuildContext context) {
    final items = supplier.itemNames;
    final itemsText = items.isEmpty ? "취급 품목 미등록" : items.join(" · ");
    final where = [
      supplier.location ?? "위치 미확인",
      ?supplier.contactEmail,
    ].join(" · ");
    return ListSelectableRow(
      selected: selected,
      onTap: onTap,
      semanticLabel:
          "${supplier.name} 거래처, ${supplier.sourceType.label}, "
          "$itemsText, $where",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LdsColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  itemsText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _muted,
                ),
              ),
              const SizedBox(width: 8),
              SupplierSourceBadge(supplier.sourceType),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            where,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _muted,
          ),
        ],
      ),
    );
  }
}
