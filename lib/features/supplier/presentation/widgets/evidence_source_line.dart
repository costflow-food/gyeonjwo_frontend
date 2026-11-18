import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../domain/supplier.dart";
import "source_mail_button.dart";

/// 근거 한 줄: '[prefix] · 자료 이름 · 확인 시각 · 메모' + 원문 보기.
class EvidenceSourceLine extends StatelessWidget {
  const EvidenceSourceLine({
    super.key,
    required this.prefix,
    required this.evidence,
  });

  final String prefix;
  final SourceEvidence? evidence;

  static const _style = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);

  @override
  Widget build(BuildContext context) {
    final value = evidence;
    if (value == null) return Text("$prefix 출처 미확인", style: _style);
    final text = [
      "$prefix · ${value.label}",
      if (value.checkedAt != null)
        "${formatSeoulDateTime(value.checkedAt!)} 확인",
      if (value.memo != null) value.memo!,
    ].join(" · ");
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: _style),
        if (value.sourceMailId != null)
          SourceMailButton(mailId: value.sourceMailId!),
      ],
    );
  }
}
