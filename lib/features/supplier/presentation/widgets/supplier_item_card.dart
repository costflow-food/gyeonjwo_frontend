import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../app/app_paths.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";
import "certification_badge.dart";

/// 취급 품목 = 접고 펼치는 카드 (`docs/design-ssot.md` 7.15).
///
/// 이름·규격 줄 전체가 펼침 단추(왼쪽 화살표 20, 접히면 -90°)이고 '근거·가격
/// 이력'은 머리 줄 오른쪽. 접힌 카드는 규격 아래 '최근 참고 견적 ○○원/kg'.
/// 펼친 카드: 요약 칸 2개(최근 참고 견적 · 마지막 실거래) → 규격 묶음(이름표가
/// 값 위, 표 아님) → 인증 → 비고.
class SupplierItemCard extends StatefulWidget {
  const SupplierItemCard({
    super.key,
    required this.item,
    required this.onOpenEvidence,
    this.initiallyExpanded = false,
  });

  final SupplierItem item;
  final VoidCallback onOpenEvidence;
  final bool initiallyExpanded;

  @override
  State<SupplierItemCard> createState() => _SupplierItemCardState();
}

class _SupplierItemCardState extends State<SupplierItemCard> {
  late bool _expanded = widget.initiallyExpanded;

  static String? _quoteText(SupplierItem item) {
    final quote = item.latestReferenceQuote;
    return quote == null
        ? null
        : "${formatDecimal(quote.unitPrice)}원/${quote.unit}";
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final quote = _quoteText(item);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.panel),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: _expanded,
                  label: "${item.itemName}, ${_expanded ? "접기" : "펼치기"}",
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 8, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedRotation(
                            turns: _expanded ? 0 : -.25,
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 150),
                            child: const Icon(
                              Icons.expand_more,
                              size: 20,
                              color: LdsColors.title,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: LdsColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.specification ?? "규격 미확인",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: LdsColors.mutedStrong,
                                  ),
                                ),
                                if (!_expanded) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    quote == null
                                        ? "최근 참고 견적 미확인"
                                        : "최근 참고 견적 $quote",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: LdsColors.title,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
                child: TextButton.icon(
                  onPressed: widget.onOpenEvidence,
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: const Text("근거·가격 이력"),
                ),
              ),
            ],
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _Body(item: item, quote: quote),
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item, required this.quote});

  final SupplierItem item;
  final String? quote;

  @override
  Widget build(BuildContext context) {
    final reference = item.latestReferenceQuote;
    final purchase = item.lastPurchase;
    final specs = [
      ("단위", item.unit),
      ("박스당 수량", item.unitsPerBox),
      ("박스당 중량", item.weightPerBox == null ? null : "${item.weightPerBox}kg"),
      ("원산지", item.origin),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Summary(
                  label: "최근 참고 견적",
                  source: "메일",
                  value: quote,
                  caption: reference?.effectiveFrom == null
                      ? null
                      : "${formatIsoDate(reference!.effectiveFrom!)} 적용",
                ),
              ),
              const SizedBox(width: 12),
              // Transactions 입구(7.12): 이 거래처·품목으로 걸러 그 거래를 엽니다.
              Expanded(
                child: _Summary(
                  label: "마지막 실거래",
                  source: "증빙",
                  value: purchase == null
                      ? null
                      : "${formatDecimal(purchase.unitPrice)}원/${purchase.unit}",
                  caption: purchase == null
                      ? null
                      : formatIsoDate(purchase.transactionDate),
                  onTap: purchase == null
                      ? null
                      : () => context.go(
                          AppPaths.transactionsFor(
                            supplierItemId: item.id,
                            itemName: item.itemName,
                            date: purchase.transactionDate,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 규격 묶음: 이름표가 값 위에 쌓이므로 표가 아니라 왼쪽 정렬(7.11).
        LayoutBuilder(
          builder: (context, constraints) {
            final perRow = constraints.maxWidth >= 480 ? 4 : 2;
            final width = (constraints.maxWidth - 16 * (perRow - 1)) / perRow;
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final (label, value) in specs)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LdsColors.mutedStrong,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          value ?? "미확인",
                          style: TextStyle(
                            fontSize: 15,
                            color: value == null
                                ? LdsColors.mutedStrong
                                : LdsColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (item.certifications.isEmpty)
          const Text(
            "인증 정보 미확인",
            style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final certification in item.certifications)
                CertificationBadge(certification),
            ],
          ),
        if (item.notes != null) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: LdsColors.lineSoft),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: "비고  ",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: item.notes),
              ],
            ),
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: LdsColors.ink,
            ),
          ),
        ],
      ],
    );
  }
}

/// 요약 칸(표 아님): 이름 + 출처 꼬리표, 가격 19/700, 날짜.
/// [onTap]이 있으면 칸 전체가 단추이고 아래 '거래내역 보기 ›'(13px `#C24A00`).
class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.source,
    required this.value,
    required this.caption,
    this.onTap,
  });

  final String label, source;
  final String? value, caption;
  final VoidCallback? onTap;

  static const _goColor = Color(0xFFC24A00);

  @override
  Widget build(BuildContext context) {
    final box = _box();
    final tap = onTap;
    if (tap == null) return box;
    final radius = BorderRadius.circular(LdsRadius.table);
    return Semantics(
      button: true,
      label: "$label $value, Invoices에서 거래 내역 보기",
      excludeSemantics: true,
      onTap: tap,
      child: LdsFocusRing(
        radius: LdsRadius.table,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: tap, borderRadius: radius, child: box),
        ),
      ),
    );
  }

  Widget _box() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: LdsColors.canvas,
      borderRadius: BorderRadius.circular(LdsRadius.table),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: LdsColors.mutedStrong,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: LdsColors.line,
                borderRadius: BorderRadius.circular(LdsRadius.button),
              ),
              child: Text(
                source,
                style: const TextStyle(fontSize: 13, color: LdsColors.label),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value ?? "미확인",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: value == null ? LdsColors.mutedStrong : LdsColors.ink,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        ],
        if (onTap != null) ...[
          const SizedBox(height: 2),
          const Text(
            "거래내역 보기 ›",
            style: TextStyle(fontSize: 13, color: _goColor),
          ),
        ],
      ],
    ),
  );
}
