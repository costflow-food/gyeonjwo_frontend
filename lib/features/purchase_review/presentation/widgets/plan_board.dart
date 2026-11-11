import "package:flutter/material.dart";

import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "plan_card.dart";
import "review_format.dart";

class PlanBoard extends StatelessWidget {
  const PlanBoard({
    super.key,
    required this.card,
    required this.busy,
    required this.onSelect,
  });

  final ReviewCard card;
  final bool busy;
  final ValueChanged<ResponsePlan> onSelect;

  static const _gap = 12.0;
  static const _minColumnWidth = 190.0;

  @override
  Widget build(BuildContext context) {
    final plans = card.plans;
    final lowestTotal = _lowestValidTotal(plans);
    final suppliers = _suppliers(plans);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth =
            (constraints.maxWidth - _gap * (plans.length - 1)) / plans.length;
        final grid = columnWidth >= _minColumnWidth;
        Widget cardFor(ResponsePlan plan) => PlanCard(
          plan: plan,
          lowest: _isLowest(plan, lowestTotal),
          difference: _difference(plan, lowestTotal),
          allocations: grid
              ? const []
              : [
                  for (final allocation in plan.allocations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AllocationCell(
                        allocation: allocation,
                        planQuantity: _planQuantity(plan),
                        lowest: _isLowest(plan, lowestTotal),
                        conditional: !plan.valid,
                        showSupplier: true,
                      ),
                    ),
                ],
        );
        if (!grid) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final plan in plans) ...[
                cardFor(plan),
                const SizedBox(height: 8),
                _SelectButton(
                  plan: plan,
                  card: card,
                  busy: busy,
                  lowest: _isLowest(plan, lowestTotal),
                  onSelect: () => onSelect(plan),
                ),
                const SizedBox(height: 16),
              ],
              for (final question in card.questions) ...[
                _ExcludedNotice(question: question),
                const SizedBox(height: 12),
              ],
            ],
          );
        }
        Widget row(Widget Function(ResponsePlan plan) cell) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, plan) in plans.indexed) ...[
                if (index > 0) const SizedBox(width: _gap),
                Expanded(child: cell(plan)),
              ],
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(cardFor),
            for (final supplier in suppliers) ...[
              const SizedBox(height: 14),
              _SupplierHeader(allocation: supplier),
              const SizedBox(height: 8),
              row((plan) {
                final allocation = plan.allocations
                    .where((a) => a.supplierId == supplier.supplierId)
                    .firstOrNull;
                return allocation == null
                    ? const _EmptyCell()
                    : _AllocationCell(
                        allocation: allocation,
                        planQuantity: _planQuantity(plan),
                        lowest: _isLowest(plan, lowestTotal),
                        conditional: !plan.valid,
                      );
              }),
            ],
            for (final question in card.questions) ...[
              const SizedBox(height: 14),
              _ExcludedNotice(question: question),
            ],
            const SizedBox(height: 14),
            row(
              (plan) => _SelectButton(
                plan: plan,
                card: card,
                busy: busy,
                lowest: _isLowest(plan, lowestTotal),
                onSelect: () => onSelect(plan),
              ),
            ),
          ],
        );
      },
    );
  }

  static num? _total(ResponsePlan plan) =>
      plan.totalAmount == null ? null : num.tryParse(plan.totalAmount!);

  static num? _lowestValidTotal(List<ResponsePlan> plans) {
    num? lowest;
    for (final plan in plans.where((plan) => plan.valid)) {
      final total = _total(plan);
      if (total != null && (lowest == null || total < lowest)) lowest = total;
    }
    return lowest;
  }

  static bool _isLowest(ResponsePlan plan, num? lowest) =>
      plan.valid && lowest != null && _total(plan) == lowest;

  static String? _difference(ResponsePlan plan, num? lowest) {
    final total = _total(plan);
    if (total == null || lowest == null || total <= lowest) return null;
    return decimal((total - lowest).toString());
  }

  static num _planQuantity(ResponsePlan plan) => plan.allocations.fold<num>(
    0,
    (sum, allocation) => sum + (num.tryParse(allocation.quantity) ?? 0),
  );

  static List<PlanAllocation> _suppliers(List<ResponsePlan> plans) {
    final seen = <String>{};
    return [
      for (final plan in plans)
        for (final allocation in plan.allocations)
          if (seen.add(allocation.supplierId)) allocation,
    ];
  }
}

class _SupplierHeader extends StatelessWidget {
  const _SupplierHeader({required this.allocation});

  final PlanAllocation allocation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: allocation.supplierName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: "  "),
          TextSpan(
            text: allocation.unitPrice == null
                ? "단가 미확인"
                : decimal(allocation.unitPrice!),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (allocation.unitPrice != null)
            TextSpan(
              text:
                  "  원${allocation.unit == null ? "" : "/${allocation.unit}"}",
              style: TextStyle(fontSize: 12, color: context.palette.muted),
            ),
        ],
      ),
    ),
  );
}

class _AllocationCell extends StatelessWidget {
  const _AllocationCell({
    required this.allocation,
    required this.planQuantity,
    required this.lowest,
    required this.conditional,
    this.showSupplier = false,
  });

  final PlanAllocation allocation;
  final num planQuantity;
  final bool lowest, conditional, showSupplier;

  @override
  Widget build(BuildContext context) {
    final quantity = num.tryParse(allocation.quantity) ?? 0;
    final share = planQuantity <= 0
        ? 0.0
        : (quantity / planQuantity).clamp(0, 1).toDouble();
    final barColor = lowest
        ? context.palette.gold
        : conditional
        ? context.palette.ink.withValues(alpha: 0.3)
        : context.palette.accent;
    final unit = allocation.unit ?? "";
    return _Cell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSupplier) ...[
            Text(
              "${allocation.supplierName} · ${perUnit(allocation.unitPrice, allocation.unit)}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              color: barColor,
              backgroundColor: context.palette.line,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: decimal(allocation.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      " | ${decimal(planQuantity.toString())}$unit"
                      "${conditional ? " · 조건부" : ""}",
                  style: TextStyle(color: context.palette.muted),
                ),
              ],
            ),
            style: TextStyle(fontSize: 13, color: context.palette.ink),
          ),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) => _Cell(
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "—",
        semanticsLabel: "배정 없음",
        style: TextStyle(color: context.palette.muted),
      ),
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 64),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.palette.line),
      boxShadow: [
        BoxShadow(
          color: context.palette.ink.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _ExcludedNotice extends StatelessWidget {
  const _ExcludedNotice({required this.question});

  final ReviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final detail =
        question.formula ??
        (question.breakEvenAmount == null
            ? null
            : "역전 기준 ${won(question.breakEvenAmount)}");
    return CustomPaint(
      painter: _HatchPainter(context.palette.ink.withValues(alpha: 0.06)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.palette.ink.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: context.palette.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${question.supplierName} · ${question.fieldLabel}: ${question.reason}",
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.muted,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8;
    for (var x = -size.height; x < size.width; x += 16) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.color != color;
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.plan,
    required this.card,
    required this.busy,
    required this.lowest,
    required this.onSelect,
  });

  final ResponsePlan plan;
  final ReviewCard card;
  final bool busy, lowest;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final decision = card.decision;
    final selected =
        plan.planId != null &&
        decision?.decision == ReviewAction.selectPlan &&
        decision?.planId == plan.planId;
    if (selected) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.palette.blush,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          "선택한 구매안",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.palette.accentText,
          ),
        ),
      );
    }
    final canSelect = card.can(ReviewAction.selectPlan) && plan.selectable;
    final reason = !plan.valid
        ? "${plan.validationLabel} 안은 아직 확정할 수 없습니다."
        : plan.planId == null
        ? "서버가 이 안의 ID를 보내지 않아 선택할 수 없습니다."
        : card.disabledMessage(ReviewAction.selectPlan);
    final label = plan.valid ? "이 안 선택" : "수용하기";
    final onPressed = canSelect && !busy ? onSelect : null;
    const shape = StadiumBorder();
    const size = Size.fromHeight(48);
    const text = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    final button = lowest
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.accent,
              foregroundColor: context.palette.onAccent,
              disabledBackgroundColor: context.palette.line,
              disabledForegroundColor: context.palette.muted,
              minimumSize: size,
              shape: shape,
              textStyle: text,
            ),
            onPressed: onPressed,
            child: Text(label),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.palette.accentText,
              disabledForegroundColor: context.palette.muted,
              side: BorderSide(
                color: onPressed == null
                    ? context.palette.line
                    : context.palette.accentText,
              ),
              minimumSize: size,
              shape: shape,
              textStyle: text,
            ),
            onPressed: onPressed,
            child: Text(label),
          );
    return onPressed == null && reason != null
        ? Tooltip(message: reason, child: button)
        : button;
  }
}
