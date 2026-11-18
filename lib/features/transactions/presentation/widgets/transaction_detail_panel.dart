import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/purchase_record.dart";
import "../../domain/transaction_listing.dart";
import "../transaction_format.dart";
import "price_change_text.dart";

/// 고른 거래의 상세 (`docs/design-ssot.md` 7.12, 상세 칸 전체): 머리
/// '{품목} · {거래처}' + 아래 규격 → 카드 '확정 정보'(이름표-값
/// 표 + Suppliers 링크) → 카드 '{품목} 확정 단가 흐름'.
///
/// 넓은 화면은 늘 고른 거래를 보여 주고, 좁은 화면은 '목록으로'가 있어
/// 닫기 단추는 두지 않습니다. 확정 방식·증빙 파일·연결된 업무는 DB에 없어
/// 두지 않습니다.
class TransactionDetailPanel extends StatelessWidget {
  const TransactionDetailPanel({
    super.key,
    required this.row,
    required this.flow,
    required this.onOpenSupplier,
  });

  final TransactionRow row;

  /// 같은 품목 거래, 오래된 순.
  final List<PurchaseRecord> flow;
  final VoidCallback onOpenSupplier;

  @override
  Widget build(BuildContext context) {
    final record = row.record;
    final previous = row.change.previous;
    return Semantics(
      container: true,
      label: "거래 상세",
      child: LdsPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${record.itemName} · ${record.supplierName}',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (record.confirmationMethod != null)
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),

                    constraints: const BoxConstraints(minWidth: 64),
                    decoration: BoxDecoration(
                      color: LdsColors.badgeNeutralBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.confirmationMethod!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LdsColors.label,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: LdsColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateText(record),
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.label,
                      ),
                    ),
                  ],
                ),
                if (record.specification != null)
                  Text(
                    record.specification!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.label,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '거래 정보',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final left = [
                  LdsKeyValueRow('확정일', text: dateText(record)),
                  LdsKeyValueRow('단가', text: unitPriceText(record)),
                ];
                final right = [
                  LdsKeyValueRow('수량', text: quantityText(record)),
                  LdsKeyValueRow('총액', text: totalText(record)),
                ];
                if (constraints.maxWidth < 560) {
                  return LdsKeyValueTable(
                    labelWidth: 96,
                    rows: [...left, ...right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LdsKeyValueTable(labelWidth: 96, rows: left),
                    ),
                    Expanded(
                      child: LdsKeyValueTable(labelWidth: 96, rows: right),
                    ),
                  ],
                );
              },
            ),
            LdsKeyValueTable(
              labelWidth: 96,
              rows: [
                LdsKeyValueRow(
                  '직전 대비',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      PriceChangeText(record, row.change),
                      if (previous != null)
                        Text(
                          '직전 ${dateText(previous)} · ${previous.supplierName} · ${unitPriceText(previous)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: LdsColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                LdsKeyValueRow(
                  '확정 방식',
                  text: record.confirmationDescription ?? '',
                ),
              ],
            ),
            const Divider(height: 48, color: LdsColors.line),
            const Text(
              '근거',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (record.evidenceName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: LdsColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.evidenceName!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (record.relatedTaskTitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '검토 카드 · ${record.relatedTaskTitle}',
                  style: const TextStyle(fontSize: 13),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '연결된 업무 없음 (Thoner 밖에서 확정된 거래)',
                  style: TextStyle(fontSize: 13, color: LdsColors.muted),
                ),
              ),
            _LinkButton(
              label: 'Suppliers에서 ${record.supplierName} 보기',
              onTap: onOpenSupplier,
            ),
            const Divider(height: 48, color: LdsColors.line),
            Text(
              '${record.itemName} 확정 단가 흐름',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _PriceFlow(flow: flow, currentId: record.id),
          ],
        ),
      ),
    );
  }
}

/// 테두리 링크 단추: 높이 최소 44, 오른쪽 '›'.
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LdsRadius.table);
    return Semantics(
      button: true,
      link: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: LdsFocusRing(
        radius: LdsRadius.table,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: LdsColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            hoverColor: LdsColors.canvas,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: LdsColors.title,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "›",
                    style: TextStyle(fontSize: 14, color: LdsColors.title),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 같은 품목 확정 단가 흐름: 날짜(MM.dd) · 거래처 · 막대 · 단가.
/// 현재 거래는 주황 막대 + 굵게.
class _PriceFlow extends StatelessWidget {
  const _PriceFlow({required this.flow, required this.currentId});

  final List<PurchaseRecord> flow;
  final String currentId;

  static const _bar = Color(0xFFFFC7A3);

  @override
  Widget build(BuildContext context) {
    final max = flow.fold<num>(0, (m, r) => r.unitPrice > m ? r.unitPrice : m);
    return Column(
      children: [
        for (final (i, record) in flow.indexed) ...[
          if (i > 0) const SizedBox(height: 6),
          _flowLine(record, max),
        ],
      ],
    );
  }

  Widget _flowLine(PurchaseRecord record, num max) {
    final current = record.id == currentId;
    final style = TextStyle(
      fontSize: 13,
      fontWeight: current ? FontWeight.w700 : FontWeight.w400,
      color: current ? LdsColors.ink : LdsColors.label,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final ratio = max <= 0 ? 0.0 : (record.unitPrice / max).toDouble();
    return Semantics(
      label:
          "${dateText(record)} ${record.supplierName} "
          "${unitPriceText(record)}${current ? ", 이 거래" : ""}",
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(dateText(record).substring(5), style: style),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              record.supplierName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: current ? LdsColors.primary : _bar,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              formatAmount(record.unitPrice),
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
