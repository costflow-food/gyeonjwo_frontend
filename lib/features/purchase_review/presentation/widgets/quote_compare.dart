import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../source_document/presentation/source_document_dialog.dart";
import "../../domain/purchase_review.dart";
import "plan_card.dart";
import "review_format.dart";

const _tax = {"EXCLUDED": "부가세 별도", "INCLUDED": "부가세 포함", "EXEMPT": "면세"};
const _checkStates = {"STATED": "원문 확인", "MISSING": "원문에 없음", "UNCLEAR": "불명확"};

/// Checks already shown on the fixed 부가세 line.
const _taxFields = {"tax_terms", "tax_basis"};

/// 비용 종류 → 원문 근거의 필드 이름.
const _costFields = {"SHIPPING": "shipping_cost"};

/// 표의 한 줄: 이름표, 이 줄에 붙는 근거 필드, 업체별 값.
class _Line {
  const _Line(this.label, this.fields, this.value);

  final String label;
  final Set<String> fields;
  final _Value Function(QuoteVersion quote) value;
}

/// 한 칸의 값. [missing]이면 '미확인' 표시입니다(0원·빈칸으로 채우지 않음).
class _Value {
  const _Value(this.text, {this.caption}) : missing = false;

  const _Value.missing([this.text = "미확인"]) : caption = null, missing = true;

  final String text;
  final String? caption;
  final bool missing;
}

/// 견적과 근거 = 비교 표 (`docs/design-ssot.md` 9.3, 7.16).
///
/// 첫 열 이름표 150, 업체 열은 같은 폭, 머리·값·근거 단추 모두 가운데.
/// 업체가 4곳을 넘으면 목록 표(9.2)로 바꿉니다. 근거 단추를 누르면 그 원문
/// 메일을 엽니다(원문 안 위치로 바로 가지는 않습니다).
class QuoteCompare extends StatelessWidget {
  const QuoteCompare({super.key, required this.quotes, required this.colors});

  /// 업체 열이 이보다 좁아지면 표를 옆으로 스크롤합니다.
  static const _minColumnWidth = 160.0;

  final List<QuoteVersion> quotes;
  final SupplierColors colors;

  List<_Line> _lines() {
    final lines = [
      _Line(
        "단가",
        const {"unit_price"},
        (quote) => quote.unitPrice == null
            ? const _Value.missing()
            : _Value(perUnit(quote.unitPrice, quote.unit)),
      ),
      _Line("부가세", _taxFields, (quote) {
        final wording = quote.checks
            .where((check) => _taxFields.contains(check.field))
            .map((check) => check.value)
            .whereType<String>()
            .firstOrNull;
        final text = _tax[quote.taxBasis] ?? wording;
        return text == null ? const _Value.missing() : _Value(text);
      }),
      _Line(
        "공급 가능량",
        const {"available_quantity"},
        (quote) => quote.availableQuantity == null
            ? const _Value.missing()
            : _Value("${decimal(quote.availableQuantity!)}${quote.unit ?? ""}"),
      ),
      _Line(
        "최소 주문",
        const {"moq", "moq_quantity"},
        (quote) =>
            quote.moq == null ? const _Value.missing() : _Value(quote.moq!),
      ),
      _Line(
        "적용일",
        const {"effective_from", "valid_until"},
        (quote) => quote.effectiveFrom == null
            ? const _Value.missing()
            : _Value(
                formatIsoDate(quote.effectiveFrom!),
                caption: quote.validUntil == null
                    ? null
                    : "${formatIsoDate(quote.validUntil!)}까지 유효",
              ),
      ),
    ];
    // 비용은 업체마다 다를 수 있어 종류별로 모읍니다.
    final costTypes = <String, String>{};
    for (final quote in quotes) {
      for (final cost in quote.costs) {
        costTypes.putIfAbsent(cost.costType, () => cost.label);
      }
    }
    for (final MapEntry(key: type, value: label) in costTypes.entries) {
      lines.add(
        _Line(label, {?_costFields[type], "cost_terms"}, (quote) {
          final cost = quote.costs
              .where((cost) => cost.costType == type)
              .firstOrNull;
          if (cost == null) return const _Value.missing("원문에 없음");
          if (cost.includedInPrice == true) {
            return _Value("단가에 포함", caption: cost.sourceText);
          }
          return cost.amount == null
              ? _Value.missing(cost.sourceText ?? "미확인")
              : _Value(won(cost.amount), caption: cost.sourceText);
        }),
      );
    }
    final checkFields = <String, String>{};
    for (final quote in quotes) {
      for (final check in quote.checks) {
        if (!_taxFields.contains(check.field)) {
          checkFields.putIfAbsent(check.field, () => check.label);
        }
      }
    }
    for (final MapEntry(key: field, value: label) in checkFields.entries) {
      lines.add(
        _Line(label, {field}, (quote) {
          final check = quote.checks
              .where((check) => check.field == field)
              .firstOrNull;
          if (check == null) return const _Value.missing();
          return check.value == null
              ? _Value.missing(_checkStates[check.state] ?? check.state)
              : _Value(check.value!);
        }),
      );
    }
    if (quotes.any((quote) => quote.itemNotes.isNotEmpty)) {
      lines.add(
        _Line(
          "품목 비고",
          const {"item_notes"},
          (quote) => quote.itemNotes.isEmpty
              ? const _Value.missing("없음")
              : _Value(quote.itemNotes.join("\n")),
        ),
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines();
    final used = {for (final line in lines) ...line.fields};
    // 표의 어느 줄에도 붙지 않는 근거는 마지막 줄에 모읍니다.
    final leftover = quotes.any(
      (quote) => quote.evidence.any((e) => !used.contains(e.field)),
    );
    Widget cell(_Line line, QuoteVersion quote, {bool start = false}) {
      final value = line.value(quote);
      final evidence = [
        for (final item in quote.evidence)
          if (line.fields.contains(item.field)) item,
      ];
      return _Cell(value: value, evidence: evidence, start: start);
    }

    Widget otherEvidence(QuoteVersion quote, {bool start = false}) => _Cell(
      value: const _Value(""),
      start: start,
      evidence: [
        for (final item in quote.evidence)
          if (!used.contains(item.field)) item,
      ],
    );

    final table = quotes.length <= 4
        ? LdsCompareTable(
            labelWidth: 150,
            options: [
              for (final quote in quotes)
                LdsCompareOption(
                  quote.supplierName,
                  marker: colors.of(quote.supplierId),
                  caption: quote.isIncumbent
                      ? "기존 거래처"
                      : "견적 ${quote.versionNo}번째",
                ),
            ],
            rows: [
              for (final line in lines)
                LdsCompareRow(line.label, [
                  for (final quote in quotes) cell(line, quote),
                ]),
              if (leftover)
                LdsCompareRow("그 밖의 근거", [
                  for (final quote in quotes) otherEvidence(quote),
                ]),
            ],
          )
        // 5곳 이상: 비교 표 대신 목록 표(9.3).
        : LdsListTable(
            columns: [
              const LdsColumn("업체", flex: 2, alignStart: true),
              for (final line in lines.take(5)) LdsColumn(line.label),
            ],
            rows: [
              for (final quote in quotes)
                LdsListRow([
                  Row(
                    children: [
                      LdsColorDot(colors.of(quote.supplierId)),
                      const SizedBox(width: 6),
                      Flexible(child: Text(quote.supplierName)),
                    ],
                  ),
                  for (final line in lines.take(5)) cell(line, quote),
                ]),
            ],
          );
    // 좁은 화면: 업체 열이 너무 좁아지지 않게 표를 옆으로 밀어 봅니다.
    final minWidth = 150.0 + quotes.length.clamp(1, 5) * _minColumnWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= minWidth
              ? table
              // 좁은 화면(휴대폰): 옆으로 밀지 않고 업체마다 이름표-값 표(9.1).
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, quote) in quotes.indexed) ...[
                      if (index > 0) const SizedBox(height: 16),
                      _SupplierHead(
                        quote: quote,
                        color: colors.of(quote.supplierId),
                      ),
                      const SizedBox(height: 8),
                      LdsKeyValueTable(
                        rows: [
                          for (final line in lines)
                            LdsKeyValueRow(
                              line.label,
                              child: cell(line, quote, start: true),
                            ),
                          if (leftover &&
                              quote.evidence.any(
                                (e) => !used.contains(e.field),
                              ))
                            LdsKeyValueRow(
                              "그 밖의 근거",
                              child: otherEvidence(quote, start: true),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        const Text(
          "근거 단추를 누르면 원문 메일을 엽니다. 미확인 값은 0원이나 빈칸으로 채우지 않습니다.",
          style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.evidence,
    this.start = false,
  });

  final _Value value;
  final List<QuoteEvidence> evidence;

  /// 이름표-값 표 안: 왼쪽 정렬(7.11). 비교 표에서는 가운데(9.3).
  final bool start;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: start
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    children: [
      if (value.text.isNotEmpty)
        value.missing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 14,
                    color: LdsColors.mutedStrong,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      value.text,
                      textAlign: start ? TextAlign.start : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.mutedStrong,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                value.text,
                textAlign: start ? TextAlign.start : TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: LdsColors.ink,
                ),
              ),
      if (value.caption != null) ...[
        const SizedBox(height: 2),
        Text(
          value.caption!,
          textAlign: start ? TextAlign.start : TextAlign.center,
          style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        ),
      ],
      if (evidence.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(
          alignment: start ? WrapAlignment.start : WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [for (final item in evidence) _EvidenceButton(item)],
        ),
      ],
    ],
  );
}

/// 근거 단추: 높이 24 이상(7.16 접근성). 누르면 원문 메일을 엽니다.
class _EvidenceButton extends StatelessWidget {
  const _EvidenceButton(this.evidence);

  final QuoteEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final raw = evidence.rawValue;
    return Tooltip(
      message: raw == null ? evidence.label : "${evidence.label} · “$raw”",
      child: Semantics(
        button: true,
        label: "${evidence.label} 근거 원문 보기, ${evidence.locationLabel}",
        excludeSemantics: true,
        child: LdsFocusRing(
          radius: 12,
          child: Material(
            color: Colors.white,
            shape: const StadiumBorder(
              side: BorderSide(color: LdsColors.borderStrong),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () =>
                  showSourceDocument(context, requestId: evidence.mailId),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_quote,
                        size: 14,
                        color: LdsColors.title,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        evidence.locationLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: LdsColors.title,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 좁은 화면의 업체 머리: 색 사각 · 이름 · 기존 거래처/견적 차수.
class _SupplierHead extends StatelessWidget {
  const _SupplierHead({required this.quote, required this.color});

  final QuoteVersion quote;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          quote.supplierName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: LdsColors.ink,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        quote.isIncumbent ? "기존 거래처" : "견적 ${quote.versionNo}번째",
        style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
      ),
    ],
  );
}
