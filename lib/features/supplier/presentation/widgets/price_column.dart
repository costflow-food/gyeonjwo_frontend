import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "price_record_tile.dart";

/// One price source. The newest record comes first and is marked.
class PriceColumn extends StatelessWidget {
  const PriceColumn({
    super.key,
    required this.title,
    required this.caption,
    required this.emptyText,
    required this.dateSuffix,
    required this.records,
  });

  final String title;
  final String caption;
  final String emptyText;
  final String dateSuffix;
  final List<PriceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: AppFontSizes.caption,
              color: muted,
            ),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(fontSize: AppFontSizes.body, color: muted),
            )
          else
            for (final (index, record) in records.indexed)
              PriceRecordTile(
                record: record,
                dateSuffix: dateSuffix,
                latest: index == 0,
              ),
        ],
      ),
    );
  }
}
