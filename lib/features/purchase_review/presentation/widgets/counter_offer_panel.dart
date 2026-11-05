import "package:flutter/material.dart";

import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "detail_line.dart";
import "review_format.dart";

/// ⑤ 역제안. 메일 발송은 메일 초안에서 따로 승인합니다.
class CounterOfferPanel extends StatelessWidget {
  const CounterOfferPanel({super.key, required this.offer});

  final CounterOffer offer;

  @override
  Widget build(BuildContext context) {
    final target = offer.target;
    final reference = offer.reference;
    final unit = reference?.unit;
    return OutlinePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offer.statusLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (offer.reason != null) ...[
            const SizedBox(height: 6),
            Text(
              offer.reason!,
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
          const SizedBox(height: 14),
          if (target != null) ...[
            DetailLine("대상", target.supplierName),
            DetailLine("목표 단가", perUnit(target.targetUnitPrice, unit)),
            for (final condition in target.conditions)
              DetailLine("조건", condition),
          ],
          if (reference != null) ...[
            DetailLine("요청 단가", perUnit(reference.requestedUnitPrice, unit)),
            DetailLine("인상 전 단가", perUnit(reference.previousUnitPrice, unit)),
            DetailLine(
              "대안보다 싸지는 상한",
              perUnit(reference.ceilingUnitPrice, unit),
            ),
            DetailLine("비교한 대안 총액", won(reference.alternativeTotal)),
            if (reference.allowedRange.length == 2)
              DetailLine(
                "제안 가능 범위",
                "${decimal(reference.allowedRange.first)}~"
                    "${decimal(reference.allowedRange.last)}원",
              ),
          ],
          if (offer.draftIds.isNotEmpty)
            const Text(
              "역제안 메일 초안은 '메일 초안'에서 확인하고 승인해 주세요.",
              style: TextStyle(fontSize: 11, color: muted),
            ),
        ],
      ),
    );
  }
}
