import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "review_format.dart";

class CounterOfferPanel extends StatelessWidget {
  const CounterOfferPanel({
    super.key,
    required this.offer,
    required this.onMailDraft,
    this.plansSelectable = false,
  });

  final CounterOffer offer;
  final VoidCallback onMailDraft;

  /// Whether a plan can still be chosen on this card; a held offer says so.
  final bool plansSelectable;

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
    // A held offer proposes nothing: its reason is the content, there is no
    // empty range box, and the draft button shows only when a draft exists.
    final hold = offer.onHold;
    final hasRange = range.length == 2;
    final showRange = !hold || summary.isNotEmpty;
    final showDraft = !hold || offer.draftIds.isNotEmpty;
    final draftButton = LdsButton(
      label: "메일 초안",
      icon: Icons.mail_outline,
      variant: LdsButtonVariant.outlinedNeutral,
      onPressed: onMailDraft,
    );
    // 인상 전 → 요청 단가: 기존 거래처가 보낸 인상 요청(시안 '인상 전·요청').
    final raise = [
      if (reference?.previousUnitPrice != null)
        "인상 전 ${perUnit(reference!.previousUnitPrice, unit)}",
      if (reference?.requestedUnitPrice != null)
        "요청 ${perUnit(reference!.requestedUnitPrice, unit)}",
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LdsColors.warningBg,
        borderRadius: BorderRadius.circular(LdsRadius.panel),
        border: Border.all(color: LdsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                "역제안",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: LdsColors.ink,
                ),
              ),
              if (hold) ...[
                const Spacer(),
                _HoldChip(offer.statusLabel),
              ] else if (target != null) ...[
                const SizedBox(width: 12),
                // A long name is cut short instead of pushing past the panel.
                Expanded(
                  child: Text(
                    target.supplierName,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.mutedStrong,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!hold || target != null) ...[
            const SizedBox(height: 4),
            Text(
              hold ? target!.supplierName : offer.statusLabel,
              style: const TextStyle(
                fontSize: 13,
                color: LdsColors.mutedStrong,
              ),
            ),
          ],
          if (raise.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              raise.join(" → "),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: LdsColors.ink,
              ),
            ),
          ],
          if (hold && offer.reason != null) ...[
            const SizedBox(height: 12),
            Text(
              offer.reason!,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
          if (target != null) ...[
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              children: [
                Text(
                  decimal(target.targetUnitPrice),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "목표 단가 원${unit == null ? "" : "/$unit"}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.mutedStrong,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (showRange) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: LdsColors.line),
                borderRadius: BorderRadius.circular(LdsRadius.table),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Held with no range: the box holds only the
                          // alternative total, so it is named for that.
                          hold && !hasRange ? "대안 총액" : "제안 가능 범위",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: LdsColors.label,
                          ),
                        ),
                        if (summary.isNotEmpty)
                          Text(
                            hold && !hasRange
                                ? won(reference!.alternativeTotal)
                                : summary.join(" · "),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: LdsColors.ink,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showDraft) ...[const SizedBox(width: 10), draftButton],
                ],
              ),
            ),
          ] else if (showDraft) ...[
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: draftButton),
          ],
          const SizedBox(height: 12),
          for (final condition in [...?target?.conditions])
            Text(
              "조건 · $condition",
              style: const TextStyle(
                fontSize: 13,
                color: LdsColors.mutedStrong,
                height: 1.6,
              ),
            ),
          if (!hold && offer.reason != null)
            Text(
              offer.reason!,
              style: const TextStyle(
                fontSize: 13,
                color: LdsColors.mutedStrong,
                height: 1.6,
              ),
            ),
          if (offer.draftIds.isNotEmpty)
            Text(
              "역제안 메일 초안은 '메일 초안'에서 확인하고 승인해 주세요.",
              style: const TextStyle(
                fontSize: 13,
                color: LdsColors.mutedStrong,
                height: 1.6,
              ),
            ),
          if (hold && target == null && !hasRange)
            Container(
              margin: EdgeInsets.only(top: showRange ? 0 : 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LdsRadius.table),
              ),
              child: Text.rich(
                TextSpan(
                  text: "목표 단가와 제안 범위는 정해지지 않았습니다.",
                  children: [
                    if (plansSelectable)
                      TextSpan(
                        text: " 구매안은 그대로 고를 수 있습니다.",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.palette.ink,
                        ),
                      ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: LdsColors.mutedStrong,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "역제안 보류" in the caution colour, where the muted status text was.
class _HoldChip extends StatelessWidget {
  const _HoldChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: cautionTint,
      borderRadius: BorderRadius.circular(LdsRadius.button),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_outline, size: 13, color: caution),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: caution,
          ),
        ),
      ],
    ),
  );
}
