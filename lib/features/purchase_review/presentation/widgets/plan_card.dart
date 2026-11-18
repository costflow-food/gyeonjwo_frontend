import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/purchase_review.dart";
import "review_format.dart";

/// 업체 색 (`docs/design-ssot.md` 3, 7.16): 같은 업체는 화면 어디서나 같은 색.
///
/// 최저 총액 안의 업체부터, 그다음 다른 안의 업체 순으로 주황 → 먹색 → …을
/// 줍니다. 구매안에 들지 않은 업체(비교 제외)는 회색입니다.
class SupplierColors {
  SupplierColors._(this._colors);

  factory SupplierColors.of(ReviewCard card, {ResponsePlan? lowest}) {
    final order = <String>[];
    for (final plan in [?lowest, ...card.plans]) {
      for (final allocation in plan.allocations) {
        if (!order.contains(allocation.supplierId)) {
          order.add(allocation.supplierId);
        }
      }
    }
    const palette = [
      LdsColors.primary,
      LdsColors.title,
      LdsColors.outline,
      LdsColors.borderStrong,
    ];
    return SupplierColors._({
      for (final (index, id) in order.indexed)
        id: palette[index.clamp(0, palette.length - 1)],
    });
  }

  final Map<String, Color> _colors;

  /// 색을 정하지 않은 빈 표(문장만 만들 때).
  static final none = SupplierColors._(const {});

  /// 구매안에 들지 않은 업체는 회색.
  Color of(String supplierId) => _colors[supplierId] ?? LdsColors.disabled;
}

/// 구매안 카드 한 장 (`docs/design-ssot.md` 7.16).
///
/// 세 카드에서 같은 줄에 오도록 칸이 늘 있습니다: 안 이름(17) · 상태 라벨 ·
/// 총액(28/800, '원' 17 붙여 씀) · 최저 대비 차액 · 설명 · 메모(없어도 빈 줄) ·
/// 업체별 배분(카드 아래쪽에 붙음) · '총액 내역 보기'. 카드 안쪽 좌우 20.
/// 바탕은 늘 흰색이고, 최저 총액 안만 주황 1px 테두리입니다.
class PlanCard extends StatefulWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.lowest,
    required this.difference,
    required this.colors,
    this.allocationRows = 0,
  });

  /// 배분 표 줄 수를 이만큼 맞춰 세 카드의 막대가 같은 높이에 옵니다.
  final int allocationRows;

  final ResponsePlan plan;

  /// 확정 가능한 안 중 총액이 가장 낮은 안: 주황 2px 테두리 + '최저 총액'.
  final bool lowest;

  /// 가장 낮은 안과의 차이(원). 계산할 수 없으면 null.
  final String? difference;
  final SupplierColors colors;

  static const padding = 20.0;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _breakdown = false;

  ResponsePlan get plan => widget.plan;
  bool get lowest => widget.lowest;
  String? get difference => widget.difference;
  SupplierColors get colors => widget.colors;
  int get allocationRows => widget.allocationRows;

  /// 확정할 수 없는 안: 메모를 주의 색으로.
  bool get _unavailable => !plan.valid;

  @override
  Widget build(BuildContext context) {
    final memo = [...plan.conditions, ...plan.adjustments];
    const padding = PlanCard.padding;
    return Container(
      padding: const EdgeInsets.fromLTRB(padding, padding, padding, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LdsRadius.panel),
        border: Border.all(
          color: lowest ? LdsColors.primary : LdsColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.typeLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: LdsColors.ink,
                  ),
                ),
              ),
              if (plan.planType == "KEEP")
                const Text(
                  "기준안",
                  style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusTag(plan: plan),
              if (lowest) const LdsTag("최저 총액", style: LdsTagStyle.solid),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: plan.totalAmount == null
                      ? "미확인"
                      : decimal(plan.totalAmount!),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (plan.totalAmount != null)
                  const TextSpan(text: "원", style: TextStyle(fontSize: 17)),
              ],
            ),
            style: const TextStyle(color: LdsColors.ink),
          ),
          const SizedBox(height: 4),
          // 없어도 줄을 남겨 세 카드의 설명이 같은 높이에서 시작합니다.
          Text(
            lowest
                ? "가장 낮음"
                : difference == null
                ? " "
                : "+$difference원",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: lowest ? LdsColors.ink : LdsColors.title,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            plan.reason ?? " ",
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: LdsColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (memo.isEmpty)
            const Text(" ", style: TextStyle(fontSize: 13, height: 1.5))
          else
            for (final note in memo)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 6),
                      child: Icon(
                        _unavailable ? Icons.info_outline : Icons.tune,
                        size: 14,
                        color: _unavailable
                            ? LdsColors.cautionText
                            : LdsColors.mutedStrong,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _unavailable
                              ? LdsColors.cautionText
                              : LdsColors.mutedStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          // 배분은 카드 아래쪽에 붙여 세 카드에서 같은 높이에 둡니다.
          const Spacer(),
          if (plan.allocations.isNotEmpty) ...[
            const SizedBox(height: 16),
            PlanAllocations(plan: plan, colors: colors, rows: allocationRows),
          ],
          const SizedBox(height: 8),
          _BreakdownToggle(
            open: _breakdown,
            onTap: () => setState(() => _breakdown = !_breakdown),
          ),
          if (_breakdown) _Breakdown(plan: plan),
        ],
      ),
    );
  }
}

/// '총액 내역 보기' 단추: 아래 꺾쇠 + 13/700.
class _BreakdownToggle extends StatelessWidget {
  const _BreakdownToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      expanded: open,
      child: LdsFocusRing(
        radius: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: LdsColors.title,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    open ? "총액 내역 접기" : "총액 내역 보기",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 총액 내역: 업체별 배정량 × 단가, 그리고 서버가 계산한 총액.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.plan});

  final ResponsePlan plan;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, height: 1.5, color: LdsColors.title);
    String? subtotal(PlanAllocation allocation) {
      final quantity = num.tryParse(allocation.quantity);
      final price = num.tryParse(allocation.unitPrice ?? "");
      if (quantity == null || price == null) return null;
      return won((quantity * price).toString());
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final allocation in plan.allocations)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "${allocation.supplierName} "
                      "${decimal(allocation.quantity)}${allocation.unit ?? ""}"
                      " × ${perUnitTight(allocation.unitPrice, allocation.unit)}",
                      style: style,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(subtotal(allocation) ?? "미확인", style: style),
                ],
              ),
            ),
          const Divider(height: 12, color: LdsColors.line),
          Row(
            children: [
              const Expanded(child: Text("총액 (서버 계산)", style: style)),
              Text(
                won(plan.totalAmount),
                style: style.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LdsColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 상태 라벨. 검토 카드는 글자 대비를 높입니다(7.16 접근성): 확정 가능
/// 초록 `#4F7A0C`, 조건부 노랑 `#8A6200`.
class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.plan});

  final ResponsePlan plan;

  @override
  Widget build(BuildContext context) {
    final (tone, text, icon) = switch (plan.validationStatus) {
      "VALID" => (
        LdsTagTone.success,
        LdsColors.successText,
        Icons.check_circle_outline,
      ),
      "INVALID" => (LdsTagTone.error, null, Icons.block),
      _ => (
        LdsTagTone.warning,
        LdsColors.cautionText,
        Icons.pause_circle_outline,
      ),
    };
    return LdsTag(
      plan.validationLabel,
      tone: tone,
      icon: icon,
      foreground: text,
    );
  }
}

/// 업체별 배분: 비율 막대 + 작은 표(업체 | 단가 | 배정량, 숫자 오른쪽 정렬).
class PlanAllocations extends StatelessWidget {
  const PlanAllocations({
    super.key,
    required this.plan,
    required this.colors,
    this.rows = 0,
  });

  final ResponsePlan plan;
  final SupplierColors colors;

  /// 최소 줄 수. 모자라면 빈 줄을 둡니다.
  final int rows;

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);
    const cell = TextStyle(fontSize: 13, height: 1.5, color: LdsColors.ink);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LdsRatioBar(
            segments: [
              for (final allocation in plan.allocations)
                LdsRatioSegment(
                  label: allocation.supplierName,
                  value: num.tryParse(allocation.quantity) ?? 0,
                  color: colors.of(allocation.supplierId),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                children: [
                  Text("업체", style: head),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text("단가", style: head, textAlign: TextAlign.right),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text("배정량", style: head, textAlign: TextAlign.right),
                  ),
                ],
              ),
              for (final allocation in plan.allocations)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          LdsColorDot(colors.of(allocation.supplierId)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(allocation.supplierName, style: cell),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        perUnitTight(allocation.unitPrice, allocation.unit),
                        textAlign: TextAlign.right,
                        style: cell,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: decimal(allocation.quantity),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: allocation.unit ?? ""),
                          ],
                        ),
                        textAlign: TextAlign.right,
                        style: cell,
                      ),
                    ),
                  ],
                ),
              for (var i = plan.allocations.length; i < rows; i++)
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(" ", style: cell),
                    ),
                    SizedBox.shrink(),
                    SizedBox.shrink(),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
