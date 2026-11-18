import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier.dart";
import "../supplier_view_model.dart";
import "source_mail_button.dart";
import "supplier_load_error.dart";

/// 가격 근거 창의 가격 이력 (`docs/design-ssot.md` 8.3): 요약 3칸 → 참고 견적
/// 표 → 실제 거래 표. 두 표는 위아래로 쌓고 열 폭을 같게 둡니다.
class PriceHistorySection extends ConsumerWidget {
  const PriceHistorySection({super.key, required this.supplierItemId});
  final String supplierItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = supplierPriceHistoryViewModelProvider(supplierItemId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("가격 이력", style: _sectionTitle),
        const SizedBox(height: 12),
        ref
            .watch(provider)
            .when(
              skipLoadingOnRefresh: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SupplierLoadError(
                error: error,
                fallback: "가격 이력을 불러오지 못했습니다.",
                onRetry: () => ref.read(provider.notifier).refresh(),
              ),
              data: (history) => PriceHistoryView(history: history),
            ),
      ],
    );
  }
}

const _sectionTitle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: LdsColors.ink,
);

/// 견적 − 실제 거래. 두 가격이 모두 있고 단위가 같을 때만 계산합니다(서버 값
/// 아님).
({String number, String unit, String caption})? priceGapOf(
  PriceRecord? quote,
  PriceRecord? actual,
) {
  if (quote == null || actual == null || quote.unit != actual.unit) {
    return null;
  }
  final quoted = double.tryParse(quote.unitPrice);
  final paid = double.tryParse(actual.unitPrice);
  if (quoted == null || paid == null || paid == 0) return null;
  final gap = quoted - paid;
  final size = gap.abs();
  final plain = size == size.roundToDouble()
      ? size.toInt().toString()
      : size.toStringAsFixed(2);
  final percent = (size / paid * 100).round();
  return (
    number:
        "${gap > 0
            ? "+"
            : gap < 0
            ? "-"
            : ""}${formatDecimal(plain)}",
    unit: "원/${quote.unit}",
    caption: gap == 0
        ? "견적과 실제 거래가 같음"
        : "견적이 $percent% ${gap > 0 ? "높음" : "낮음"}",
  );
}

class PriceHistoryView extends StatelessWidget {
  const PriceHistoryView({super.key, required this.history});

  final PriceHistory history;

  /// 두 표가 같이 쓰는 열 폭 비율(적용일·거래일 / 단가 / 조건·수량 / 출처·증빙).
  static const columnFlex = [2, 2, 2, 3];

  /// 이보다 좁으면 기록마다 이름표-값 표로 쌓습니다.
  static const tableMinWidth = 560.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < tableMinWidth;
      final quote = history.latestReferenceQuote;
      final actual = history.lastActualPurchase;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(quote: quote, actual: actual, narrow: narrow),
          const SizedBox(height: 24),
          const _TableTitle("참고 견적", "메일 견적 기준 · 실제 거래가 아님"),
          const SizedBox(height: 8),
          _PriceTable(
            key: const ValueKey("quote-table"),
            records: history.referenceQuotes,
            narrow: narrow,
            emptyText: "확인된 참고 견적이 없습니다.",
            labels: const ["적용일", "단가", "조건", "출처"],
            third: (record) => record.conditions,
          ),
          const SizedBox(height: 24),
          const _TableTitle("실제 거래", "영수증·거래명세서 등 증빙 기준"),
          const SizedBox(height: 8),
          _PriceTable(
            key: const ValueKey("purchase-table"),
            records: history.actualPurchases,
            narrow: narrow,
            emptyText: "확인된 실거래 이력이 없습니다.",
            labels: const ["거래일", "단가", "수량", "증빙"],
            third: (record) => record.quantity == null
                ? null
                : "${formatDecimal(record.quantity!)}${record.unit}",
          ),
        ],
      );
    },
  );
}

class _TableTitle extends StatelessWidget {
  const _TableTitle(this.title, this.caption);

  final String title, caption;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(title, style: _sectionTitle),
      Text(
        caption,
        style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
      ),
    ],
  );
}

/// 참고 견적·실제 거래 목록 표. 첫 줄(가장 최근)에 '최신'.
class _PriceTable extends StatelessWidget {
  const _PriceTable({
    super.key,
    required this.records,
    required this.narrow,
    required this.emptyText,
    required this.labels,
    required this.third,
  });

  final List<PriceRecord> records;
  final bool narrow;
  final String emptyText;

  /// 날짜 · 단가 · 셋째 칸 · 출처.
  final List<String> labels;
  final String? Function(PriceRecord) third;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: LdsColors.line),
          borderRadius: BorderRadius.circular(LdsRadius.table),
        ),
        child: Text(
          emptyText,
          style: const TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
        ),
      );
    }
    Widget date(PriceRecord record, bool latest) => Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: narrow ? WrapAlignment.start : WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(record.date == null ? "날짜 미확인" : formatIsoDate(record.date!)),
        if (latest) const LdsLatestTag(),
      ],
    );
    Widget price(PriceRecord record) =>
        LdsNumberUnit(formatDecimal(record.unitPrice), "원/${record.unit}");
    Widget source(PriceRecord record) => Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(record.sourceLabel),
        if (record.sourceMailId != null)
          SourceMailButton(mailId: record.sourceMailId!),
      ],
    );
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, record) in records.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            LdsKeyValueTable(
              labelWidth: 96,
              rows: [
                LdsKeyValueRow(labels[0], child: date(record, index == 0)),
                LdsKeyValueRow(labels[1], child: price(record)),
                if (third(record) case final value?)
                  LdsKeyValueRow(labels[2], text: value),
                LdsKeyValueRow(labels[3], child: source(record)),
              ],
            ),
          ],
        ],
      );
    }
    const flex = PriceHistoryView.columnFlex;
    return LdsListTable(
      columns: [
        LdsColumn(labels[0], flex: flex[0]),
        LdsColumn(labels[1], flex: flex[1]),
        LdsColumn(labels[2], flex: flex[2]),
        LdsColumn(labels[3], flex: flex[3], alignStart: true),
      ],
      rows: [
        for (final (index, record) in records.indexed)
          LdsListRow(latest: index == 0, [
            date(record, index == 0),
            price(record),
            // 빈 칸은 비웁니다(9.0).
            Text(third(record) ?? ""),
            source(record),
          ]),
      ],
    );
  }
}

/// 요약 3칸(표 아님): 최근 참고 견적 · 최근 실제 거래 · 차이.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.quote,
    required this.actual,
    required this.narrow,
  });

  final PriceRecord? quote, actual;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final gap = priceGapOf(quote, actual);
    String? dated(PriceRecord? record, String suffix) =>
        record?.date == null ? null : "${formatIsoDate(record!.date!)} $suffix";
    final cells = [
      _SummaryCell(
        label: "최근 참고 견적",
        number: quote == null ? null : formatDecimal(quote!.unitPrice),
        unit: quote == null ? null : "원/${quote!.unit}",
        caption: dated(quote, "적용"),
      ),
      _SummaryCell(
        label: "최근 실제 거래",
        number: actual == null ? null : formatDecimal(actual!.unitPrice),
        unit: actual == null ? null : "원/${actual!.unit}",
        caption: dated(actual, "거래"),
      ),
      _SummaryCell(
        label: "견적 – 실제 거래",
        number: gap?.number,
        unit: gap?.unit,
        missing: "비교 불가",
        caption:
            gap?.caption ??
            (quote != null && actual != null && quote!.unit != actual!.unit
                ? "단위가 달라 비교하지 않습니다."
                : "두 가격이 모두 있어야 비교합니다."),
        highlight: true,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      clipBehavior: Clip.antiAlias,
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, cell) in cells.indexed) ...[
                  if (index > 0)
                    const Divider(height: 1, color: LdsColors.line),
                  cell,
                ],
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, cell) in cells.indexed) ...[
                    if (index > 0)
                      const VerticalDivider(width: 1, color: LdsColors.line),
                    Expanded(child: cell),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.number,
    required this.unit,
    required this.caption,
    this.missing = "미확인",
    this.highlight = false,
  });

  final String label, missing;
  final String? number, unit, caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    color: highlight ? LdsColors.primaryRow : null,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        ),
        const SizedBox(height: 6),
        if (number == null)
          Text(
            missing,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: LdsColors.mutedStrong,
            ),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: " $unit"),
              ],
            ),
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: LdsColors.ink,
            ),
          ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        ],
      ],
    ),
  );
}
