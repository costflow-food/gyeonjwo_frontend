import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "detail_line.dart";
import "review_format.dart";

const _tax = {"EXCLUDED": "부가세 별도", "INCLUDED": "부가세 포함"};
const _checkStates = {"STATED": "원문 확인", "MISSING": "원문에 없음", "UNCLEAR": "불명확"};

/// API-13 견적 한 버전과 필드별 원문 근거.
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.quote});

  final QuoteVersion quote;

  @override
  Widget build(BuildContext context) {
    return OutlinePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quote.supplierName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                quote.isIncumbent ? "기존 거래처" : "견적 ${quote.versionNo}번째",
                style: const TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DetailLine("단가", perUnit(quote.unitPrice, quote.unit)),
          DetailLine("부가세", _tax[quote.taxBasis] ?? "미확인"),
          DetailLine(
            "공급 가능량",
            quote.availableQuantity == null
                ? "미확인"
                : "${decimal(quote.availableQuantity!)}${quote.unit ?? ""}",
          ),
          DetailLine("최소 주문", quote.moq ?? "미확인"),
          DetailLine(
            "적용일",
            quote.effectiveFrom == null
                ? "미확인"
                : formatIsoDate(quote.effectiveFrom!),
            caption: quote.validUntil == null
                ? null
                : "유효기간 ${formatIsoDate(quote.validUntil!)}까지",
          ),
          for (final cost in quote.costs)
            DetailLine(
              cost.label,
              cost.includedInPrice == true
                  ? "단가에 포함"
                  : (cost.amount == null ? "미확인" : won(cost.amount)),
              caption: cost.sourceText,
            ),
          for (final check in quote.checks)
            DetailLine(
              check.label,
              check.value ?? (_checkStates[check.state] ?? check.state),
              mutedValue: check.value == null,
            ),
          for (final note in quote.itemNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "비고 · $note",
                style: const TextStyle(fontSize: 13, color: muted),
              ),
            ),
          if (quote.evidence.isNotEmpty) ...[
            const Divider(color: line, height: 20),
            _EvidenceSection(evidence: quote.evidence),
          ],
        ],
      ),
    );
  }
}

/// 원문 근거 목록. 처음엔 접혀 있고 제목 줄을 누르면 펼쳐집니다.
class _EvidenceSection extends StatefulWidget {
  const _EvidenceSection({required this.evidence});

  final List<QuoteEvidence> evidence;

  @override
  State<_EvidenceSection> createState() => _EvidenceSectionState();
}

class _EvidenceSectionState extends State<_EvidenceSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text(
                  "원문 근거",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Text(
                  "${widget.evidence.length}건",
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(Icons.expand_more, size: 20, color: muted),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          for (final evidence in widget.evidence)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${evidence.label} · “${evidence.rawValue ?? "-"}” · "
                "${evidence.locationLabel}",
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
        ],
      ],
    );
  }
}
