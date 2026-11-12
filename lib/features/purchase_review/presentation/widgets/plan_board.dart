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
    this.folding = false,
  });

  final ReviewCard card;
  final bool busy;
  final ValueChanged<ResponsePlan> onSelect;

  /// Phone: every plan as one line, in the server's order; the tapped one
  /// opens.
  final bool folding;

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
        final grid = !folding && columnWidth >= _minColumnWidth;
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
        if (folding) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlanList(
                card: card,
                busy: busy,
                lowestTotal: lowestTotal,
                onSelect: onSelect,
              ),
              for (final question in card.questions) ...[
                const SizedBox(height: 12),
                _ExcludedNotice(question: question),
              ],
            ],
          );
        }
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
    this.showReason = false,
    required this.onSelect,
  });

  final ResponsePlan plan;
  final ReviewCard card;
  final bool busy, lowest;

  /// Writes why the plan cannot be chosen under the button.
  final bool showReason;
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
    // Phone: a tooltip needs a long press, so the reason is written out.
    if (showReason && !canSelect && reason != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 6),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.palette.muted),
          ),
        ],
      );
    }
    return onPressed == null && reason != null
        ? Tooltip(message: reason, child: button)
        : button;
  }
}

/// Phone: the plans as a list to compare, one line each. The tapped plan
/// opens to its notes, allocation and select button; nothing scrolls sideways.
class _PlanList extends StatefulWidget {
  const _PlanList({
    required this.card,
    required this.busy,
    required this.lowestTotal,
    required this.onSelect,
  });

  final ReviewCard card;
  final bool busy;
  final num? lowestTotal;
  final ValueChanged<ResponsePlan> onSelect;

  @override
  State<_PlanList> createState() => _PlanListState();
}

class _PlanListState extends State<_PlanList> {
  /// The open plan; null when all are folded.
  ResponsePlan? _open;

  bool _selected(ResponsePlan plan) {
    final decision = widget.card.decision;
    return plan.planId != null &&
        decision?.decision == ReviewAction.selectPlan &&
        decision?.planId == plan.planId;
  }

  /// The chosen plan, else the first that can be chosen, else the first.
  ResponsePlan? get _initial {
    final plans = widget.card.plans;
    return plans.where(_selected).firstOrNull ??
        plans.where((plan) => plan.selectable).firstOrNull ??
        plans.firstOrNull;
  }

  /// The same plan on a reloaded card, where the plans are new objects.
  bool _same(ResponsePlan plan, ResponsePlan other) =>
      identical(plan, other) ||
      (plan.planId != null
          ? plan.planId == other.planId
          : other.planId == null && plan.planType == other.planType);

  @override
  void initState() {
    super.initState();
    _open = _initial;
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.card.plans;
    // Folded by hand stays folded; an open plan that left the card (a new
    // review) gives way to the starting choice.
    final remembered = _open;
    final open = remembered == null
        ? null
        : plans.where((plan) => _same(plan, remembered)).firstOrNull ??
              _initial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, plan) in plans.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          _PlanRow(
            plan: plan,
            card: widget.card,
            busy: widget.busy,
            open: plan == open || plans.length == 1,
            foldable: plans.length > 1,
            selected: _selected(plan),
            lowest: PlanBoard._isLowest(plan, widget.lowestTotal),
            difference: PlanBoard._difference(plan, widget.lowestTotal),
            onToggle: () => setState(() => _open = plan == open ? null : plan),
            onSelect: () => widget.onSelect(plan),
          ),
        ],
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.card,
    required this.busy,
    required this.open,
    required this.foldable,
    required this.selected,
    required this.lowest,
    required this.difference,
    required this.onToggle,
    required this.onSelect,
  });

  final ResponsePlan plan;
  final ReviewCard card;
  final bool busy, open, foldable, selected, lowest;
  final String? difference;
  final VoidCallback onToggle, onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final notes = [...plan.conditions, ...plan.adjustments, ?plan.reason];
    final (chip, chipBackground, chipText) = lowest
        ? (
            "${plan.validationLabel} · 가장 낮음",
            palette.gold,
            const Color(0xFF1E1E1E),
          )
        : plan.valid
        ? (plan.validationLabel, palette.blush, palette.accentText)
        : (plan.validationLabel, cautionTint, caution);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (selected) ...[
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: palette.accentText,
                          semanticLabel: "선택한 구매안",
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          plan.typeLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: chipBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: chipText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // The total never takes more than about half the row: a longer
            // one shrinks instead of pushing the name out.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * .55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      won(plan.totalAmount),
                      // Capped so a large text setting leaves room for the name.
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.3),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (lowest)
                    Text(
                      "최저",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.isDark ? palette.gold : caution,
                      ),
                    )
                  else if (difference != null)
                    Text(
                      "+$difference",
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                ],
              ),
            ),
            if (foldable) ...[
              const SizedBox(width: 4),
              Icon(
                open ? Icons.expand_less : Icons.expand_more,
                size: 22,
                color: palette.muted,
              ),
            ],
          ],
        ),
      ),
    );
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: open && foldable ? palette.accentText : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (foldable)
            Semantics(
              button: true,
              expanded: open,
              child: InkWell(onTap: onToggle, child: header),
            )
          else
            header,
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: palette.line)),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final note in notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        if (notes.isNotEmpty) const SizedBox(height: 6),
                        for (final allocation in plan.allocations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AllocationCell(
                              allocation: allocation,
                              planQuantity: PlanBoard._planQuantity(plan),
                              lowest: lowest,
                              conditional: !plan.valid,
                              showSupplier: true,
                            ),
                          ),
                        _SelectButton(
                          plan: plan,
                          card: card,
                          busy: busy,
                          lowest: lowest,
                          showReason: true,
                          onSelect: onSelect,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
