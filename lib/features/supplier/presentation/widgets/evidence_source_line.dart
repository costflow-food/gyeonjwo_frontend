import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "source_mail_button.dart";

/// Source label and check time, with the original mail when one exists.
class EvidenceSourceLine extends StatelessWidget {
  const EvidenceSourceLine({
    super.key,
    required this.prefix,
    required this.evidence,
  });

  final String prefix;
  final SourceEvidence? evidence;

  @override
  Widget build(BuildContext context) {
    final value = evidence;
    if (value == null) {
      return Text(
        "$prefix 출처 미확인",
        style: const TextStyle(fontSize: AppFontSizes.secondary, color: muted),
      );
    }
    final text = [
      "$prefix · ${value.label}",
      if (value.checkedAt != null)
        "${formatSeoulDateTime(value.checkedAt!)} 확인",
      if (value.memo != null) value.memo!,
    ].join(" · ");
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: AppFontSizes.secondary,
            color: muted,
          ),
        ),
        if (value.sourceMailId != null)
          SourceMailButton(mailId: value.sourceMailId!),
      ],
    );
  }
}
