import "package:flutter/material.dart";

import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "review_format.dart";

/// ④ 구매안 한 개. 선택은 최신 카드의 확정 가능(VALID) 안에서만 열립니다.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.card,
    required this.busy,
    required this.onSelect,
  });

  final ResponsePlan plan;
  final ReviewCard card;
  final bool busy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final decision = card.decision;
    final selected =
        plan.planId != null &&
        decision?.decision == ReviewAction.selectPlan &&
        decision?.planId == plan.planId;
    final canSelect = card.can(ReviewAction.selectPlan) && plan.selectable;
    final blocked = card.disabledMessage(ReviewAction.selectPlan);
    return OutlinePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.typeLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Chip(
                plan.validationLabel,
                strong: plan.valid,
                warning: !plan.valid,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text("총액", style: TextStyle(fontSize: 11, color: muted)),
          const SizedBox(height: 6),
          Text(
            won(plan.totalAmount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 14),
          for (final allocation in plan.allocations)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${allocation.supplierName} · "
                "${decimal(allocation.quantity)}${allocation.unit ?? ""} × "
                "${perUnit(allocation.unitPrice, allocation.unit)}",
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          for (final note in [...plan.conditions, ...plan.adjustments])
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "· $note",
                style: const TextStyle(fontSize: 11, color: muted, height: 1.6),
              ),
            ),
          if (plan.reason != null) ...[
            const SizedBox(height: 10),
            Text(
              plan.reason!,
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
          const SizedBox(height: 16),
          if (selected)
            const _Chip("선택한 구매안", strong: true)
          else if (canSelect)
            FilledButton(
              style: WorkspaceButtonStyles.filled,
              onPressed: busy ? null : onSelect,
              child: const Text("이 안 선택"),
            )
          else if (!plan.valid)
            Text(
              "${plan.validationLabel} 안은 확정 선택할 수 없어요.",
              style: const TextStyle(fontSize: 11, color: muted),
            )
          else if (plan.planId == null)
            const Text(
              "서버가 이 안의 ID를 보내지 않아 선택할 수 없어요. 보류나 검토 확인은 할 수 있어요.",
              style: TextStyle(fontSize: 11, color: muted),
            )
          else if (blocked != null)
            Text(blocked, style: const TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.strong = false, this.warning = false});

  final String text;
  final bool strong, warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: strong ? ink : (warning ? blush : Colors.transparent),
      border: Border.all(color: strong ? ink : (warning ? blush : line)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: strong ? Colors.white : (warning ? accent : ink),
      ),
    ),
  );
}
