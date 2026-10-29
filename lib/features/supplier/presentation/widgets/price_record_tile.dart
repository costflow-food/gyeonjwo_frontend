import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "source_mail_button.dart";

class PriceRecordTile extends StatelessWidget {
  const PriceRecordTile({
    super.key,
    required this.record,
    required this.dateSuffix,
    required this.latest,
  });

  final PriceRecord record;
  final String dateSuffix;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final date = record.date == null
        ? "날짜 미확인"
        : "${formatIsoDate(record.date!)} $dateSuffix";
    const captionStyle = TextStyle(
      fontSize: AppFontSizes.caption,
      color: muted,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: latest ? accent : line, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "${formatDecimal(record.unitPrice)}원/${record.unit}",
                style: const TextStyle(
                  fontSize: AppFontSizes.cardTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (latest)
                const Text(
                  "최신",
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            [
              date,
              if (record.quantity != null)
                "${formatDecimal(record.quantity!)}${record.unit}",
            ].join(" · "),
            style: const TextStyle(fontSize: AppFontSizes.secondary),
          ),
          if (record.conditions != null) ...[
            const SizedBox(height: 3),
            Text(
              record.conditions!,
              style: const TextStyle(
                fontSize: AppFontSizes.secondary,
                color: muted,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text("출처 · ${record.sourceLabel}", style: captionStyle),
              if (record.sourceMailId != null)
                SourceMailButton(mailId: record.sourceMailId!),
            ],
          ),
        ],
      ),
    );
  }
}
