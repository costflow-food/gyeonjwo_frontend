import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/workspace_colors.dart';
import '../../shared/widgets/workspace_shell.dart';
import '../../shared/widgets/responsive_columns.dart';
import '../../shared/widgets/outline_panel.dart';
import '../../shared/widgets/preview_button.dart';

import 'purchase_review_preview_data.dart';
import 'widgets/request_summary.dart';
import 'widgets/supplier_card.dart';

class PurchaseReviewView extends StatelessWidget {
  const PurchaseReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return WorkspaceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('업무 큐로'),
              style: TextButton.styleFrom(
                foregroundColor: muted,
                textStyle: const TextStyle(fontSize: 12),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PURCHASE REVIEW',
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '단가변경 검토',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'REQ-2026-1019-003 · 합성 시연 사례',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              );
              const button = PreviewButton(
                '요청 원문 보기',
                icon: Icons.description_outlined,
              );
              if (constraints.maxWidth < 600 * textScale) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, SizedBox(height: 16), button],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  SizedBox(width: 16),
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const RequestSummary(),
          const SizedBox(height: 24),
          const Text(
            '거래처 조건 비교',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 10,
            children: [
              Text(
                '동일 규격과 변경 검토 물량 600kg을 기준으로 살펴보세요.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              Text(
                '기존 거래처 1 · DB 신규 후보 2',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ResponsiveColumns(
            minItemWidth: 300 * textScale,
            children: [
              for (final supplier in supplierPreviews)
                SupplierCard(
                  supplier,
                  key: ValueKey('supplier-${supplier.letter}'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const OutlinePanel(
            padding: EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '단가 비교용 구매금액과 총구매비용은 다릅니다. ',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'B·C사의 600kg 금액에는 미확인 운송비·기타 물류비가 포함되지 않았습니다. 후보의 공급 가능 여부와 총비용은 추가 확인이 필요하며, 카드 순서는 추천 순위가 아닙니다.',
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 11, color: muted, height: 1.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '출처: 요청 메일 · 계약서 · 구매계획 · 보유 DB 견적 / 모든 값은 합성 시연 데이터입니다.',
            style: TextStyle(color: muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
