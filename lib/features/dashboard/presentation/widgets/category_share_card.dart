import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/dashboard_insights.dart";
import "dashboard_card.dart";

/// 품목별 비중 색: 순위 비중이라 주황 진하기 3단계(시안 그대로).
const _shareColors = [
  LdsColors.primary,
  LdsColors.chartShare2,
  LdsColors.chartShare3,
];

Color _shareColor(int rank) => _shareColors[rank.clamp(0, 2)];

/// 품목별 구매 비중 카드 (`docs/design-ssot.md` 7.9.2): 위쪽 기간을 따릅니다.
///
/// 기간 합계 + 직전 기간 대비 + 비율 막대 + 품목 줄(이름·직전 비중·금액·비중).
/// [fill]이면 옆 카드 높이에 맞춰 품목 줄이 남는 높이를 나눠 씁니다.
class CategoryShareCard extends StatelessWidget {
  const CategoryShareCard({super.key, required this.data, this.fill = false});

  final CategoryShareSummary data;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final (rank, item) in data.items.indexed)
        _ShareRow(item: item, color: _shareColor(rank), fill: fill),
    ];
    final list = <Widget>[
      for (final (index, row) in rows.indexed) ...[
        if (index > 0) const Divider(height: 1, color: LdsColors.line),
        fill ? Expanded(child: row) : row,
      ],
    ];
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardCardHeader(
            title: "품목별 구매 비중",
            caption: "선택한 기간의 견적 금액 기준",
          ),
          const SizedBox(height: 24),
          Text("기간 합계", style: dashText(13, FontWeight.w400, LdsColors.label)),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                "${formatNumber(data.total)}원",
                style: dashText(
                  28,
                  FontWeight.w800,
                  LdsColors.ink,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              if (data.changePercent != 0) _ChangeTag(data.changePercent),
            ],
          ),
          const SizedBox(height: 16),
          LdsRatioBar(
            segments: [
              for (final (rank, item) in data.items.indexed)
                LdsRatioSegment(
                  label: item.name,
                  value: item.percent,
                  color: _shareColor(rank),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (fill) Expanded(child: Column(children: list)) else ...list,
        ],
      ),
    );
  }
}

/// '직전 기간보다 8% 절감'(초록) / '… 증가'(빨강).
class _ChangeTag extends StatelessWidget {
  const _ChangeTag(this.percent);

  final int percent;

  @override
  Widget build(BuildContext context) {
    final saved = percent < 0;
    return LdsTag(
      "직전 기간보다 ${percent.abs()}% ${saved ? "절감" : "증가"}",
      tone: saved ? LdsTagTone.success : LdsTagTone.error,
      foreground: saved ? LdsColors.successText : LdsColors.errorText,
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.item,
    required this.color,
    required this.fill,
  });

  final CategoryShare item;
  final Color color;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    const numbers = [FontFeature.tabularFigures()];
    return Semantics(
      container: true,
      label:
          "${item.name} ${formatNumber(item.amount)}원, ${item.percent}%, "
          "직전 기간 ${item.prevPercent}%",
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: fill ? 12 : 16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: dashText(15, FontWeight.w700, LdsColors.ink),
                  ),
                  Text(
                    "직전 기간 ${item.prevPercent}%",
                    style: dashText(13, FontWeight.w400, LdsColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${formatNumber(item.amount)}원",
              style: dashText(
                15,
                FontWeight.w400,
                LdsColors.title,
              ).copyWith(fontFeatures: numbers),
            ),
            SizedBox(
              width: 56,
              child: Text(
                "${item.percent}%",
                textAlign: TextAlign.right,
                style: dashText(
                  15,
                  FontWeight.w800,
                  LdsColors.ink,
                ).copyWith(fontFeatures: numbers),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
