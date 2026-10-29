import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/send_settings.dart";

/// Suppliers that automatic sends may reach. Nothing here means "everyone".
class AllowedSupplierList extends StatelessWidget {
  const AllowedSupplierList({
    super.key,
    required this.suppliers,
    required this.allowedIds,
    required this.onToggle,
  });

  final List<AllowedSupplier> suppliers;
  final Set<String> allowedIds;
  final void Function(String id, bool allowed) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final supplier in suppliers)
          SizedBox(
            width: 250,
            child: CheckboxListTile(
              activeColor: accent,
              value: allowedIds.contains(supplier.id),
              onChanged: (checked) => onToggle(supplier.id, checked ?? false),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                supplier.name,
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                supplier.email ?? "이메일 미확인",
                style: const TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
