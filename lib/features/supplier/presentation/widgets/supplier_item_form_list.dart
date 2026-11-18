import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../supplier_form_controllers.dart";
import "supplier_form_group_title.dart";
import "supplier_item_form.dart";

/// Handled items with add and remove. Zero items is allowed.
class SupplierItemFormList extends StatelessWidget {
  const SupplierItemFormList({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    this.editing = false,
  });

  final bool editing;
  final List<SupplierItemFields> items;
  final VoidCallback onAdd;
  final ValueChanged<SupplierItemFields> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SupplierFormGroupTitle(
                "취급 품목 ${items.length}",
                "후보 선정은 취급 품목을 근거로 합니다.",
              ),
            ),
            const SizedBox(width: 12),
            LdsButton(
              label: "품목 추가",
              icon: Icons.add,
              size: LdsButtonSize.small,
              variant: LdsButtonVariant.outlinedNeutral,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text(
            "취급 품목 없이 등록하면 후보 선정의 취급 근거로 쓰이지 않습니다.",
            style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        for (final (index, item) in items.indexed) ...[
          // ObjectKey keeps each item's fields attached after a removal.
          SupplierItemForm(
            editing: editing,
            key: ObjectKey(item),
            index: index,
            fields: item,
            onRemove: () => onRemove(item),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
