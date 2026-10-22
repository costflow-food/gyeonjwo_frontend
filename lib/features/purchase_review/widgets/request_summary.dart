import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';
import '../../../shared/widgets/responsive_columns.dart';
import '../../../shared/widgets/outline_panel.dart';

import 'summary_metric.dart';

class RequestSummary extends StatelessWidget {
  const RequestSummary({super.key});

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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '냉동 딸기 단가 인상 요청',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'A사 · 냉동 · 무가당 · 10kg/박스',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              const date = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('적용 요청일', style: TextStyle(fontSize: 10, color: muted)),
                  SizedBox(height: 6),
                  Text(
                    '11월 1일',
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
            children: const [
              SummaryMetric('기존 단가', '5,000', '원/kg', '현재 계약 기준'),
              SummaryMetric('요청 단가', '5,500', '원/kg', '단가 인상 요청 +10%'),
              SummaryMetric('변경 검토 물량', '600', 'kg', '11월 전체 물량 중 변경 대상'),
              SummaryMetric(
                '현재 요청의 월 비용 영향',
                '+300,000',
                '원',
                '기존 조건 대비 · 부대비용 전후 동일',
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
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '11월 전체 구매계획  ',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    TextSpan(
                      text: '1,000kg',
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
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(color: Color(0xFF444548)),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(color: Color(0xFFF4A2AA)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                '▪ 고정단가 400kg',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              const Text(
                '▪ 변경 검토 600kg',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
