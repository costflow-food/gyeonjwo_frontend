import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
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
  });

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
                "후보 선정은 취급 품목을 근거로 합니다. 인증은 증빙 확인 전까지 미확인으로 저장됩니다.",
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                "품목 추가",
                style: TextStyle(fontSize: AppFontSizes.buttonSmall),
              ),
              style: TextButton.styleFrom(foregroundColor: ink),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text(
            "취급 품목 없이 등록하면 후보 선정의 취급 근거로 쓰이지 않습니다.",
            style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
          ),
        for (final (index, item) in items.indexed) ...[
          // ObjectKey keeps each item's fields attached after a removal.
          SupplierItemForm(
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
