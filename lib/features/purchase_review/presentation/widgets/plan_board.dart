import "dart:ui" show PathMetric;

import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/purchase_review.dart";
import "plan_card.dart";
import "review_format.dart";

/// 구매안 비교 = 나란한 카드 3장 (`docs/design-ssot.md` 7.16).
///
/// 서버 순서 그대로 놓고, 폭은 같고 높이는 가장 긴 카드에 맞춥니다. 선택 단추는
/// 카드 아래 12에 칸 폭 전체(높이 44). 900px 미만 화면이나 카드가 좁아지는
/// 폭에서는 한 줄에 한 장입니다.
class PlanBoard extends StatelessWidget {
  const PlanBoard({
    super.key,
    required this.card,
    required this.busy,
    required this.onSelect,
    required this.colors,
  });

  final ReviewCard card;
  final bool busy;
  final ValueChanged<ResponsePlan> onSelect;
  final SupplierColors colors;

  static const gap = 16.0;
  static const _minCardWidth = 260.0;

  /// 이 화면 폭 미만에서는 한 줄에 한 장(SSOT 부록).
  static const stackWidth = 900.0;

  @override
  Widget build(BuildContext context) {
    final plans = card.plans;
    final lowestTotal = lowestValidTotal(plans);
    final allocationRows = plans.fold<int>(
      0,
      (most, plan) =>
          plan.allocations.length > most ? plan.allocations.length : most,
    );
    // 나란할 때만 배분 표 줄 수를 맞춥니다(막대 높이를 같게).
    Widget cardFor(ResponsePlan plan, {bool stacked = false}) => PlanCard(
      plan: plan,
      lowest: _isLowest(plan, lowestTotal),
      difference: _difference(plan, lowestTotal),
      colors: colors,
      allocationRows: stacked ? 0 : allocationRows,
    );
    Widget selectFor(ResponsePlan plan, {required bool stacked}) => PlanSelect(
      plan: plan,
      card: card,
      busy: busy,
      lowest: _isLowest(plan, lowestTotal),
      showReason: stacked,
      onSelect: () => onSelect(plan),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - gap * (plans.length - 1)) / plans.length;
        final stacked =
            MediaQuery.sizeOf(context).width < stackWidth ||
            cardWidth < _minCardWidth;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, plan) in plans.indexed) ...[
                if (index > 0) const SizedBox(height: 24),
                IntrinsicHeight(child: cardFor(plan, stacked: true)),
                const SizedBox(height: 12),
                selectFor(plan, stacked: true),
              ],
            ],
          );
        }
        Widget row(Widget Function(ResponsePlan plan) cell) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, plan) in plans.indexed) ...[
                if (index > 0) const SizedBox(width: gap),
                Expanded(child: cell(plan)),
              ],
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(cardFor),
            const SizedBox(height: 12),
            row((plan) => selectFor(plan, stacked: false)),
          ],
        );
      },
    );
  }

  static num? _total(ResponsePlan plan) =>
      plan.totalAmount == null ? null : num.tryParse(plan.totalAmount!);

  /// 확정 가능한 안 중 가장 낮은 총액.
  static num? lowestValidTotal(List<ResponsePlan> plans) {
    num? lowest;
    for (final plan in plans.where((plan) => plan.valid)) {
      final total = _total(plan);
      if (total != null && (lowest == null || total < lowest)) lowest = total;
    }
    return lowest;
  }

  /// 확정 가능한 안 중 총액이 가장 낮은 안. 없으면 null.
  static ResponsePlan? lowestPlan(List<ResponsePlan> plans) {
    final lowest = lowestValidTotal(plans);
    return plans.where((plan) => _isLowest(plan, lowest)).firstOrNull;
  }

  static bool _isLowest(ResponsePlan plan, num? lowest) =>
      plan.valid && lowest != null && _total(plan) == lowest;

  static String? _difference(ResponsePlan plan, num? lowest) {
    final total = _total(plan);
    if (total == null || lowest == null || total <= lowest) return null;
    return decimal((total - lowest).toString());
  }
}

/// 구매안 선택 단추: 칸 폭 전체, 높이 44. 최저 안 = 채운 단추, 나머지 = 테두리
/// 단추. 확정할 수 없는 안은 단추 대신 점선 상자에 이유를 적습니다(7.16).
class PlanSelect extends StatelessWidget {
  const PlanSelect({
    super.key,
    required this.plan,
    required this.card,
    required this.busy,
    required this.lowest,
    required this.onSelect,
    this.showReason = false,
  });

  static const height = 44.0;

  final ResponsePlan plan;
  final ReviewCard card;
  final bool busy, lowest;

  /// 한 줄에 한 장일 때: 고를 수 없는 이유를 단추 아래에 적습니다(툴팁은
  /// 휴대폰에서 길게 눌러야 보입니다).
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
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LdsColors.primarySoft,
          borderRadius: BorderRadius.circular(LdsRadius.button),
        ),
        child: const Text(
          "선택한 구매안",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: LdsColors.primary,
          ),
        ),
      );
    }
    if (!plan.valid) {
      return _Unavailable("선택 불가 · ${plan.validationLabel} 안은 아직 확정할 수 없습니다.");
    }
    final canSelect = card.can(ReviewAction.selectPlan) && plan.selectable;
    final reason = plan.planId == null
        ? "서버가 이 안의 ID를 보내지 않아 선택할 수 없습니다."
        : card.disabledMessage(ReviewAction.selectPlan);
    final onPressed = canSelect && !busy ? onSelect : null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LdsRadius.button),
    );
    const size = Size.fromHeight(height);
    const text = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
    final button = lowest
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LdsColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: LdsColors.lineSoft,
              disabledForegroundColor: LdsColors.disabled,
              minimumSize: size,
              shape: shape,
              textStyle: text,
              elevation: 0,
            ),
            onPressed: onPressed,
            child: const Text("선택"),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: LdsColors.title,
              disabledForegroundColor: LdsColors.disabled,
              side: BorderSide(
                color: onPressed == null
                    ? LdsColors.line
                    : LdsColors.borderStrong,
              ),
              minimumSize: size,
              shape: shape,
              textStyle: text,
            ),
            onPressed: onPressed,
            child: const Text("선택"),
          );
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
            style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        ],
      );
    }
    return onPressed == null && reason != null
        ? Tooltip(message: reason, child: button)
        : button;
  }
}

/// 고를 수 없는 안: 점선 상자 안에 이유.
class _Unavailable extends StatelessWidget {
  const _Unavailable(this.reason);

  final String reason;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const _DashedBorder(),
    child: Container(
      constraints: const BoxConstraints(minHeight: PlanSelect.height),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 14,
            color: LdsColors.mutedStrong,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: LdsColors.mutedStrong,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(LdsRadius.button),
        ),
      );
    final paint = Paint()
      ..color = LdsColors.disabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
}
