import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/responsive_columns.dart";
import "../../../../shared/widgets/outline_panel.dart";

import "summary_metric.dart";
import "../../domain/purchase_review.dart";
import "../../../../shared/formatters.dart";

class RequestSummary extends StatelessWidget {
  const RequestSummary({super.key, required this.review});

  final PurchaseReview review;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return OutlinePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: line),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: muted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "${review.supplierName} · ${review.specification}",
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final date = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('적용 요청일', style: TextStyle(fontSize: 10, color: muted)),
                  SizedBox(height: 6),
                  Text(
                    review.effectiveDate,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              );
              if (constraints.maxWidth < 600 * textScale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 16), date],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 16),
                  date,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ResponsiveColumns(
            minItemWidth: 210 * textScale,
            maxColumns: 4,
            children: [
              SummaryMetric(
                "기존 단가",
                formatNumber(review.existingUnitPrice),
                "원/kg",
                "현재 계약 기준",
              ),
              SummaryMetric(
                "요청 단가",
                formatNumber(review.requestedUnitPrice),
                "원/kg",
                "거래처 요청 기준",
              ),
              SummaryMetric(
                "변경 검토 물량",
                formatNumber(review.reviewQuantity),
                "kg",
                "${review.periodLabel} 전체 물량 중 변경 대상",
              ),
              SummaryMetric(
                '현재 요청의 월 비용 영향',
                "${review.monthlyCostImpact > 0 ? "+" : ""}${formatNumber(review.monthlyCostImpact)}",
                '원',
                review.impactNote,
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: line),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${review.periodLabel} 전체 구매계획  ",
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    TextSpan(
                      text: "${formatNumber(review.plannedQuantity)}kg",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: review.fixedQuantity > 0
                            ? review.fixedQuantity
                            : 1,
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(color: Color(0xFF444548)),
                        ),
                      ),
                      Expanded(
                        flex: review.reviewQuantity > 0
                            ? review.reviewQuantity
                            : 1,
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(color: Color(0xFFF4A2AA)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                "▪ 고정단가 ${formatNumber(review.fixedQuantity)}kg",
                style: TextStyle(fontSize: 10, color: muted),
              ),
              Text(
                "▪ 변경 검토 ${formatNumber(review.reviewQuantity)}kg",
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
