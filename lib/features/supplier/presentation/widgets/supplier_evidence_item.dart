import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";
import "certification_badge.dart";
import "evidence_source_line.dart";
import "supplier_evidence_supplier.dart";

/// 가격 근거 창 '업체·품목 상세'의 품목 조건: 이름표-값 표.
class SupplierEvidenceItem extends StatelessWidget {
  const SupplierEvidenceItem({super.key, required this.item});
  final SupplierItem item;

  static const _muted = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);

  @override
  Widget build(BuildContext context) {
    final notes = item.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("취급 품목 조건", style: evidenceSectionTitle),
        const SizedBox(height: 8),
        LdsKeyValueTable(
          rows: [
            evidenceRow("규격", item.specification),
            evidenceRow("단위", item.unit),
            evidenceRow("박스당 수량", item.unitsPerBox),
            evidenceRow(
              "박스당 중량",
              item.weightPerBox == null ? null : "${item.weightPerBox}kg",
            ),
            evidenceRow("원산지", item.origin),
            LdsKeyValueRow(
              "인증",
              child: item.certifications.isEmpty
                  ? const Text(
                      "인증 정보 미확인",
                      style: TextStyle(
                        fontSize: 15,
                        color: LdsColors.mutedStrong,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (index, certification)
                            in item.certifications.indexed)
                          Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 0 : 6),
                            child: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                CertificationBadge(certification),
                                Text(
                                  certification.validUntil == null
                                      ? "유효기간 미확인"
                                      : "${formatIsoDate(certification.validUntil!)}까지",
                                  style: _muted,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            LdsKeyValueRow(
              "품목 비고",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    notes ?? "기록된 비고가 없습니다.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: notes == null
                          ? LdsColors.mutedStrong
                          : LdsColors.ink,
                    ),
                  ),
                  if (notes != null) ...[
                    const SizedBox(height: 4),
                    EvidenceSourceLine(
                      prefix: "비고 근거",
                      evidence: item.notesEvidence,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
