import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";
import "../supplier_evidence_dialog.dart";
import "evidence_source_line.dart";
import "supplier_fact.dart";
import "supplier_item_card.dart";
import "supplier_section_title.dart";
import "supplier_source_badge.dart";

class SupplierDetailContent extends StatelessWidget {
  const SupplierDetailContent({super.key, required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              supplier.name,
              style: const TextStyle(
                fontSize: AppFontSizes.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
            SupplierSourceBadge(supplier.sourceType),
          ],
        ),
        const SizedBox(height: 20),
        const SupplierSectionTitle("업체 정보"),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            SupplierFact("사업자번호", supplier.businessRegistrationNo),
            SupplierFact("담당자", supplier.contact.name),
            SupplierFact("이메일", supplier.contactEmail, width: 240),
            SupplierFact("전화", supplier.contact.phone),
            SupplierFact("위치", supplier.location),
          ],
        ),
        const SizedBox(height: 16),
        EvidenceSourceLine(prefix: "기준자료", evidence: supplier.evidence),
        const SizedBox(height: 24),
        const Divider(color: line),
        const SizedBox(height: 16),
        SupplierSectionTitle("취급 품목 ${supplier.items.length}"),
        const SizedBox(height: 12),
        if (supplier.items.isEmpty)
          const Text(
            "등록된 취급 품목이 없습니다. 품목이 없으면 후보 선정의 취급 근거로 쓰이지 않습니다.",
            style: TextStyle(fontSize: AppFontSizes.body, color: muted),
          )
        else
          for (final item in supplier.items) ...[
            SupplierItemCard(
              item: item,
              onOpenEvidence: () => showSupplierEvidenceDialog(
                context,
                supplier: supplier,
                item: item,
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
