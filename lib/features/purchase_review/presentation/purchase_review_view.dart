import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:go_router/go_router.dart';

import "../../../shared/workspace_colors.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../../../shared/widgets/responsive_columns.dart";
import "../../../shared/widgets/outline_panel.dart";
import "../../../shared/widgets/preview_button.dart";

import "../domain/purchase_review.dart";
import "purchase_review_view_model.dart";
import "../../../shared/formatters.dart";
import "../../../shared/widgets/async_content.dart";
import 'widgets/request_summary.dart';
import 'widgets/supplier_card.dart';

class PurchaseReviewView extends ConsumerWidget {
  const PurchaseReviewView({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = purchaseReviewViewModelProvider(requestId);
    return WorkspaceShell(
      child: AsyncContent<PurchaseReview>(
        value: ref.watch(provider),
        onRetry: ref.read(provider.notifier).refresh,
        builder: (review) => _PurchaseReviewContent(review: review),
      ),
    );
  }
}

class _PurchaseReviewContent extends StatelessWidget {
  const _PurchaseReviewContent({required this.review});

  final PurchaseReview review;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Column(
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
            final heading = Column(
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
                  "${review.requestId} · 합성 시연 사례",
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            );
            const button = PreviewButton(
              '요청 원문 보기',
              icon: Icons.description_outlined,
            );
            if (constraints.maxWidth < 600 * textScale) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, SizedBox(height: 16), button],
              );
            }
            return Row(
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
        RequestSummary(review: review),
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 10,
          children: [
            Text(
              "동일 규격과 변경 검토 물량 ${formatNumber(review.reviewQuantity)}kg을 기준으로 살펴보세요.",
              style: TextStyle(fontSize: 11, color: muted),
            ),
            Text(
              "기존 거래처 ${review.suppliers.where((supplier) => supplier.existing).length} · DB 신규 후보 ${review.suppliers.where((supplier) => !supplier.existing).length}",
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ResponsiveColumns(
          minItemWidth: 300 * textScale,
          children: [
            for (final supplier in review.suppliers)
              SupplierCard(
                supplier,
                review: review,
                key: ValueKey('supplier-${supplier.letter}'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinePanel(
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
                      TextSpan(text: review.costNote),
                    ],
                  ),
                  style: TextStyle(fontSize: 11, color: muted, height: 1.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(review.sourceNote, style: TextStyle(color: muted, fontSize: 10)),
        const SizedBox(height: 12),
      ],
    );
  }
}
