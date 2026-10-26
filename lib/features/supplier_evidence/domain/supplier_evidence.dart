/// Temporary app models; these do not prescribe database tables.
class SupplierEvidence {
  SupplierEvidence({
    required this.requestId,
    required this.supplierLetter,
    required this.subtitle,
    required this.impactCaption,
    required this.monthlyCostImpact,
    required this.impactNote,
    required List<EvidenceLine> costLines,
    required List<String> crossCheckFormulas,
    required this.crossCheckNote,
    required this.disclaimer,
    required List<EvidenceSection> sections,
  }) : costLines = List.unmodifiable(costLines),
       crossCheckFormulas = List.unmodifiable(crossCheckFormulas),
       sections = List.unmodifiable(sections);

  final String requestId,
      supplierLetter,
      subtitle,
      impactCaption,
      impactNote,
      crossCheckNote,
      disclaimer;
  // null이면 부대비용이 확인되지 않아 월 비용 영향을 확정할 수 없습니다.
  final int? monthlyCostImpact;
  final List<EvidenceLine> costLines;
  final List<String> crossCheckFormulas;
  final List<EvidenceSection> sections;
}

class EvidenceLine {
  const EvidenceLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.unconfirmed = false,
  });

  final String label, value;
  final bool emphasized;
  // 자료로 확인되지 않아 총비용을 확정하지 못하게 만드는 항목입니다.
  final bool unconfirmed;
}

class EvidenceSection {
  const EvidenceSection({required this.title, required this.body, this.tag});

  final String title, body;
  final String? tag;
}
