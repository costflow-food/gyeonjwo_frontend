import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "certification_badge.dart";
import "evidence_source_line.dart";
import "supplier_fact.dart";
import "supplier_section_title.dart";

/// Item terms, certifications with validity, and the free-text note.
/// The note is a memo; it never excludes a candidate on its own.
class SupplierEvidenceItem extends StatelessWidget {
  const SupplierEvidenceItem({super.key, required this.item});
  final SupplierItem item;

  @override
  Widget build(BuildContext context) {
    const captionStyle = TextStyle(
      fontSize: AppFontSizes.caption,
      color: muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SupplierSectionTitle("취급 품목 조건", large: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          children: [
            SupplierFact("규격", item.specification, width: 240),
            SupplierFact("단위", item.unit, width: 90),
            SupplierFact("박스당 수량", item.unitsPerBox, width: 90),
            SupplierFact(
              "박스당 중량",
              item.weightPerBox == null ? null : "${item.weightPerBox}kg",
              width: 90,
            ),
            SupplierFact("원산지", item.origin),
          ],
        ),
        const SizedBox(height: 18),
        const Text("인증", style: captionStyle),
        const SizedBox(height: 6),
        if (item.certifications.isEmpty)
          const Text(
            "인증 정보 미확인",
            style: TextStyle(fontSize: AppFontSizes.body, color: muted),
          )
        else ...[
          for (final certification in item.certifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CertificationBadge(certification),
                  Text(
                    certification.validUntil == null
                        ? "유효기간 미확인"
                        : "${formatIsoDate(certification.validUntil!)}까지",
                    style: const TextStyle(
                      fontSize: AppFontSizes.secondary,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 18),
        const Text("품목 비고", style: captionStyle),
        const SizedBox(height: 6),
        SelectableText(
          item.notes ?? "기록된 비고가 없습니다.",
          style: TextStyle(
            fontSize: AppFontSizes.body,
            height: 1.55,
            color: item.notes == null ? muted : ink,
          ),
        ),
        if (item.notes != null) ...[
          const SizedBox(height: 10),
          EvidenceSourceLine(prefix: "비고 근거", evidence: item.notesEvidence),
        ],
      ],
    );
  }
}
