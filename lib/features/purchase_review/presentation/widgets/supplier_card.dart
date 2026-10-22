import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/widgets/note_line.dart";

import "../../domain/purchase_review.dart";
import "../../../../shared/formatters.dart";
import 'detail_line.dart';

class SupplierCard extends StatelessWidget {
  const SupplierCard(this.data, {super.key, required this.review});
  final PurchaseReview review;
  final SupplierQuote data;

  @override
  Widget build(BuildContext context) {
    return OutlinePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: line),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.letter,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF62666C),
                  ),
                ),
              ),
              const Spacer(),
              if (data.existing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '기존 거래처',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                )
              else
                const Text(
                  'DB 신규 후보',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${data.letter}사',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            data.existing ? '이번 단가변경 요청 거래처' : '보유 DB 등록 · 거래 이력 없음',
            style: const TextStyle(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 24),
          Text(
            data.existing ? '요청 단가' : '견적 단가',
            style: const TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatNumber(data.unitPrice),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const TextSpan(
                  text: ' 원/kg',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.existing
                ? "기존 단가 ${formatNumber(review.existingUnitPrice)}원/kg"
                : '보유 DB 견적 기준',
            style: const TextStyle(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 16),
          const Divider(color: line),
          const SizedBox(height: 12),
          DetailLine("규격", data.specification),
          DetailLine('최소 주문 수량', data.minimum),
          DetailLine('공급 소요기간', data.leadTime, mutedValue: data.existing),
          DetailLine("재고", data.stock, mutedValue: true),
          DetailLine(
            '운송비',
            formatMonthlyCost(data.shippingMonthlyCost),
            caption: data.existing ? '단가 미포함 · 회사 별도 부담' : '비용·부담 조건 확인 필요',
            mutedValue: !data.existing,
          ),
          DetailLine(
            '기타 물류비',
            formatMonthlyCost(data.logisticsMonthlyCost),
            caption: data.existing ? '단가 미포함 · 회사 별도 부담' : '비용·부담 조건 확인 필요',
            mutedValue: !data.existing,
          ),
          const SizedBox(height: 12),
          OutlinePanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.existing
                      ? "변경 검토 ${formatNumber(review.reviewQuantity)}kg · 구매금액"
                      : "변경 검토 ${formatNumber(review.reviewQuantity)}kg · 단가 비교용 구매금액",
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatNumber(data.purchaseAmount),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const TextSpan(
                        text: ' 원',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: line),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      '월 전체 총구매비용',
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                    Text(
                      data.monthlyTotalCost == null
                          ? "확정 불가"
                          : "${formatNumber(data.monthlyTotalCost!)}원",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.monthlyCostNote,
                  style: const TextStyle(
                    fontSize: 9,
                    color: muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NoteLine(
            data.existing
                ? '공급 기간과 재고는 추가 확인이 필요합니다.'
                : '운송비·기타 물류비·재고 확인이 필요합니다.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: ink,
                side: const BorderSide(color: Color(0xFFB4B7BD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data.letter}사 상세 근거 보기',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
