import "package:flutter/material.dart";

import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "review_format.dart";

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.lowest,
    required this.difference,
    this.allocation,
  });

  final ResponsePlan plan;

  final bool lowest;

  /// 가장 낮은 안과의 차이(원). 계산할 수 없으면 null.
  final String? difference;

  /// 배정 칸. 카드 아래쪽에 붙습니다.
  final Widget? allocation;

  @override
  Widget build(BuildContext context) {
    final notes = [...plan.conditions, ...plan.adjustments, ?plan.reason];
    return Container(
      constraints: const BoxConstraints(minHeight: 196),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.deepLight, context.palette.deep],
        ),
        boxShadow: [
          BoxShadow(
            color: context.palette.ink.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // The gold glow sits under the content, so the allocation cell keeps
      // its own colour.
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: lowest
            ? BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                gradient: RadialGradient(
                  center: Alignment(.85, 1),
                  radius: 1.1,
                  colors: [
                    context.palette.gold.withValues(alpha: 0.42),
                    context.palette.gold.withValues(alpha: 0.0),
                  ],
                ),
              )
            : null,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          // The amount comes first so it sits at the same height in every
          // column; the allocation keeps to the bottom edge.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan.typeLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(plan: plan, lowest: lowest),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: plan.totalAmount == null
                              ? "미확인"
                              : decimal(plan.totalAmount!),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (plan.totalAmount != null)
                          const TextSpan(
                            text: " 원",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (lowest)
                    const Text(
                      "최저",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE3C68A),
                      ),
                    )
                  else if (difference != null)
                    Text(
                      "+$difference",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.palette.onDeepMuted,
                      ),
                    ),
                  for (final (index, note) in notes.indexed)
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 10 : 4),
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.onDeepMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
              if (allocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: allocation,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.plan, required this.lowest});

  final ResponsePlan plan;
  final bool lowest;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground, border) = lowest
        ? (
            "${plan.validationLabel} · 가장 낮음",
            context.palette.gold,
            const Color(0xFF1E1E1E),
            null,
          )
        : plan.valid
        ? (plan.validationLabel, const Color(0x24FFFFFF), Colors.white, null)
        : (
            plan.validationLabel,
            const Color(0x1AFFFFFF),
            Colors.white,
            const Color(0x8CFFFFFF),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        // Always there, so every chip is the same height.
        border: Border.all(color: border ?? Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
