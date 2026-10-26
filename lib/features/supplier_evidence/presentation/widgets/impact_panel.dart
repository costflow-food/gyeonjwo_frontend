import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/outline_panel.dart";

import "../../domain/supplier_evidence.dart";
import "../../../../shared/formatters.dart";

class ImpactPanel extends StatelessWidget {
  const ImpactPanel({super.key, required this.evidence});

  final SupplierEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final impact = evidence.monthlyCostImpact;
    final unconfirmed = [
      for (final line in evidence.costLines)
        if (line.unconfirmed) line.label,
    ];
    return OutlinePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evidence.impactCaption,
            style: const TextStyle(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                impact == null
                    ? '월 비용 영향 확정 불가'
                    : "월 비용 영향 ${impact > 0 ? "+" : ""}${formatNumber(impact)}원",
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              if (impact != null) _DirectionChip(impact),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evidence.impactNote,
            style: const TextStyle(fontSize: 11, color: muted, height: 1.6),
          ),
          if (unconfirmed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: blush,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.error_outline, size: 14, color: accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '확인 필요 ${unconfirmed.length}건 · ${unconfirmed.join(", ")}',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 금액의 부호만으로 판단하지 않도록 방향을 화살표와 글자로 함께 보여 줍니다.
class _DirectionChip extends StatelessWidget {
  const _DirectionChip(this.impact);

  final int impact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, tint) = switch (impact) {
      > 0 => ('비용 증가', Icons.arrow_upward, accent, blush),
      < 0 => (
        '비용 절감',
        Icons.arrow_downward,
        positive,
        positive.withValues(alpha: 0.1),
      ),
      _ => ('변동 없음', Icons.remove, muted, line),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
