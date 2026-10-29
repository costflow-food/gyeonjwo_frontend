import "package:flutter/material.dart";

import "../../domain/supplier.dart";
import "evidence_source_line.dart";
import "supplier_fact.dart";
import "supplier_section_title.dart";
import "supplier_source_badge.dart";

/// Contact, location, and where the reference data came from.
class SupplierEvidenceSupplier extends StatelessWidget {
  const SupplierEvidenceSupplier({super.key, required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SupplierSectionTitle(
          "업체",
          large: true,
          trailing: SupplierSourceBadge(supplier.sourceType),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          children: [
            SupplierFact("담당자", supplier.contact.name),
            SupplierFact("이메일", supplier.contactEmail, width: 240),
            SupplierFact("전화", supplier.contact.phone),
            SupplierFact("위치", supplier.location),
          ],
        ),
        const SizedBox(height: 14),
        EvidenceSourceLine(prefix: "기준자료", evidence: supplier.evidence),
      ],
    );
  }
}
