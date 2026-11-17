import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";
import "evidence_source_line.dart";
import "supplier_source_badge.dart";

/// 가격 근거 창 '업체·품목 상세'의 업체 정보: 이름표-값 표.
class SupplierEvidenceSupplier extends StatelessWidget {
  const SupplierEvidenceSupplier({super.key, required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text("업체", style: evidenceSectionTitle),
            const SizedBox(width: 8),
            SupplierSourceBadge(supplier.sourceType),
          ],
        ),
        const SizedBox(height: 8),
        LdsKeyValueTable(
          rows: [
            evidenceRow("담당자", supplier.contact.name),
            evidenceRow("이메일", supplier.contactEmail),
            evidenceRow("전화", supplier.contact.phone),
            evidenceRow("위치", supplier.location),
            LdsKeyValueRow(
              "기준자료",
              child: EvidenceSourceLine(
                prefix: "기준자료",
                evidence: supplier.evidence,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const evidenceSectionTitle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: LdsColors.ink,
);

/// 값이 없으면 빈칸 대신 '미확인'(9.0).
LdsKeyValueRow evidenceRow(String label, String? value) => LdsKeyValueRow(
  label,
  child: SelectableText(
    value ?? "미확인",
    style: TextStyle(
      fontSize: 15,
      height: 1.6,
      color: value == null ? LdsColors.mutedStrong : LdsColors.ink,
    ),
  ),
);
