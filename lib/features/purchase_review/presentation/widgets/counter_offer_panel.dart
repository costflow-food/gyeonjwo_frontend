import "package:flutter/material.dart";

import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "review_format.dart";

class CounterOfferPanel extends StatelessWidget {
  const CounterOfferPanel({
    super.key,
    required this.offer,
    required this.onMailDraft,
  });

  final CounterOffer offer;
  final VoidCallback onMailDraft;

  @override
  Widget build(BuildContext context) {
    final target = offer.target;
    final reference = offer.reference;
    final unit = reference?.unit;
    final range = reference?.allowedRange ?? const [];
    final summary = [
      if (range.length == 2)
        "${decimal(range.first)}원 ~ ${decimal(range.last)}원",
      if (reference?.alternativeTotal != null)
        "대안 총액 ${won(reference!.alternativeTotal)}",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "역제안",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            if (target != null)
              Text(
                target.supplierName,
                style: TextStyle(fontSize: 13, color: context.palette.muted),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          offer.statusLabel,
          style: TextStyle(fontSize: 12, color: context.palette.muted),
        ),
        if (target != null) ...[
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            children: [
              Text(
                decimal(target.targetUnitPrice),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "목표 단가 원${unit == null ? "" : "/$unit"}",
                  style: TextStyle(fontSize: 13, color: context.palette.muted),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.palette.panel,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.palette.ink.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "제안 가능 범위",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (summary.isNotEmpty)
                      Text(
                        summary.join(" · "),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.palette.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: WorkspaceButtonStyles.outlined(context),
                onPressed: onMailDraft,
                child: const Text("메일 초안"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final condition in [...?target?.conditions])
          Text(
            "조건 · $condition",
            style: TextStyle(
              fontSize: 12,
              color: context.palette.muted,
              height: 1.6,
            ),
          ),
        if (offer.reason != null)
          Text(
            offer.reason!,
            style: TextStyle(
              fontSize: 12,
              color: context.palette.muted,
              height: 1.6,
            ),
          ),
        if (offer.draftIds.isNotEmpty)
          Text(
            "역제안 메일 초안은 '메일 초안'에서 확인하고 승인해 주세요.",
            style: TextStyle(
              fontSize: 12,
              color: context.palette.muted,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}
