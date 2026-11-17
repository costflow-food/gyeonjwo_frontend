import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';
import 'lds_tag.dart';

// 표 3종 (`docs/design-ssot.md` 9장). 공통(9.0): 바깥 틀 1px `#E5E7EA`, 모서리 8,
// 흰 배경, 줄 사이 1px `#F3F4F6`, 칸 좌우 16. 본문 15px `#191F28`, 보조 13px `#5E6876`.

const _valueStyle = TextStyle(fontSize: 15, height: 1.6, color: LdsColors.ink);

/// 표 머리·이름표 글자. 이름표는 전체 글자 크기 보정에서 뺍니다(7.11).
const _labelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 1.3,
  color: LdsColors.label,
);

class _TableFrame extends StatelessWidget {
  const _TableFrame({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(LdsRadius.table),
    ),
    // 테두리는 칸 배경(이름표 `#F9FAFB`, 머리 줄) 위에 그려야 가려지지 않습니다.
    foregroundDecoration: BoxDecoration(
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.table),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(LdsRadius.table),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, color: LdsColors.lineSoft),
            row,
          ],
        ],
      ),
    ),
  );
}

/// 이름표 칸: 고정 폭, 배경 `#F9FAFB`, 14px/700 `#4E5968`, 가운데 (9.1·7.11).
class _LabelCell extends StatelessWidget {
  const _LabelCell(this.label, {required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    color: LdsColors.canvas,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Text(
      label,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: _labelStyle,
    ),
  );
}

/// 이름표-값 표의 한 줄. [value]가 문자열이면 [text]를, 위젯이면 [child]를 씁니다.
class LdsKeyValueRow {
  const LdsKeyValueRow(this.label, {this.text, this.child, this.trailing})
    : assert((text == null) != (child == null), 'text나 child 중 하나만');

  final String label;
  final String? text;
  final Widget? child;

  /// 3칸 표의 메모·상태. 줄 오른쪽 끝에 둡니다(7.11).
  final Widget? trailing;
}

/// 이름표-값 표 (`docs/design-ssot.md` 9.1, 7.11): 한 대상의 정보.
///
/// 이름표 칸 폭 112(내용에 따라 96~136), 값은 왼쪽 정렬·이름표에서 16, 줄 높이 최소 44.
/// 값이 두 줄이 되면 이름표와 값 모두 세로 가운데입니다.
class LdsKeyValueTable extends StatelessWidget {
  const LdsKeyValueTable({super.key, required this.rows, this.labelWidth = 112})
    : assert(labelWidth >= 96 && labelWidth <= 136);

  final List<LdsKeyValueRow> rows;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => _TableFrame(
    rows: [
      for (final row in rows)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LabelCell(row.label, width: labelWidth),
                const SizedBox(width: LdsSpace.labelValueGap),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: row.child ?? Text(row.text!, style: _valueStyle),
                    ),
                  ),
                ),
                if (row.trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Center(child: row.trailing),
                  ),
                const SizedBox(width: LdsSpace.tableCellX),
              ],
            ),
          ),
        ),
    ],
  );
}

/// 목록 표의 열. 날짜·단가·수량·금액·짧은 상태는 가운데, 이름·글은 왼쪽(9.2).
class LdsColumn {
  const LdsColumn(this.label, {this.flex = 1, this.alignStart = false});

  final String label;
  final int flex;

  /// 품목·거래처·출처·증빙처럼 이름·글이면 true(왼쪽 정렬).
  final bool alignStart;
}

class LdsListRow {
  const LdsListRow(
    this.cells, {
    this.latest = false,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  final List<Widget> cells;

  /// 가장 최근 줄: 배경 `#FFF7F2`. '최신' 라벨은 날짜 칸 등에 [LdsLatestTag]로 붙입니다.
  final bool latest;

  /// 고른 줄(목록·상세 화면): 배경 `#FFF4EC` + 왼쪽 주황 3px.
  final bool selected;

  /// 있으면 줄 전체가 누를 수 있는 단추입니다(hover `#F9FAFB`).
  final VoidCallback? onTap;

  /// 줄을 단추로 읽을 때의 이름.
  final String? semanticLabel;
}

/// 목록 표 (`docs/design-ssot.md` 9.2): 같은 종류 기록 여러 건.
///
/// 머리 줄 높이 40·배경 `#F9FAFB`·13px/700 `#4E5968`·모든 칸 가운데·아래 1px `#E5E7EA`.
/// 줄 높이 최소 48. 여러 건을 카드로 쌓지 않습니다.
class LdsListTable extends StatelessWidget {
  const LdsListTable({super.key, required this.columns, required this.rows});

  final List<LdsColumn> columns;
  final List<LdsListRow> rows;

  @override
  Widget build(BuildContext context) {
    assert(rows.every((row) => row.cells.length == columns.length));
    Widget cell(LdsColumn column, Widget child) => Expanded(
      flex: column.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LdsSpace.tableCellX,
          vertical: 10,
        ),
        child: Align(
          alignment: column.alignStart
              ? Alignment.centerLeft
              : Alignment.center,
          child: DefaultTextStyle.merge(
            style: _valueStyle,
            textAlign: column.alignStart ? TextAlign.start : TextAlign.center,
            child: child,
          ),
        ),
      ),
    );
    return _TableFrame(
      rows: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: LdsColors.canvas,
            border: Border(bottom: BorderSide(color: LdsColors.line)),
          ),
          child: Row(
            children: [
              for (final column in columns)
                Expanded(
                  flex: column.flex,
                  child: Text(
                    column.label,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: _labelStyle.copyWith(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        for (final row in rows) _row(row, cell),
      ],
    );
  }
}

extension on LdsListTable {
  Widget _row(LdsListRow row, Widget Function(LdsColumn, Widget) cell) {
    final line = Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: row.selected
            ? LdsColors.selectedRow
            : row.latest
            ? LdsColors.primaryRow
            : null,
        border: row.selected
            ? const Border(left: BorderSide(color: LdsColors.primary, width: 3))
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, column) in columns.indexed)
              cell(column, row.cells[i]),
          ],
        ),
      ),
    );
    final onTap = row.onTap;
    if (onTap == null) return line;
    return Semantics(
      button: true,
      selected: row.selected,
      label: row.semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, hoverColor: LdsColors.canvas, child: line),
      ),
    );
  }
}

/// 비교 표의 한 안(업체).
class LdsCompareOption {
  const LdsCompareOption(
    this.title, {
    this.recommended = false,
    this.marker,
    this.caption,
  });

  final String title;

  /// 이름 앞 업체 색 사각(10). 같은 업체는 화면 안에서 같은 색입니다(3장).
  final Color? marker;

  /// 이름 아래 짧은 설명(예: '기존 거래처', '견적 1번째').
  final String? caption;

  /// 추천 안: 열 전체 `#FFF7F2` + 머리 칸 위 주황 3px + '추천' 라벨.
  final bool recommended;
}

class LdsCompareRow {
  const LdsCompareRow(this.label, this.values);

  final String label;
  final List<Widget> values;
}

/// 비교 표 (`docs/design-ssot.md` 9.3): 여러 안을 같은 항목으로 좌우 비교.
///
/// 첫 열은 이름표 칸(폭 112~150, 검토 카드 150). 안 열은 같은 폭, 머리와 값 모두 가운데.
/// 안은 최대 4개이고, 넘으면 목록 표([LdsListTable])로 바꿉니다.
class LdsCompareTable extends StatelessWidget {
  const LdsCompareTable({
    super.key,
    required this.options,
    required this.rows,
    this.labelWidth = 150,
  }) : assert(labelWidth >= 112 && labelWidth <= 150);

  final List<LdsCompareOption> options;
  final List<LdsCompareRow> rows;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    assert(options.isNotEmpty && options.length <= 4, '안은 1~4개 (넘으면 목록 표)');
    assert(rows.every((row) => row.values.length == options.length));
    Widget optionCell(
      LdsCompareOption option,
      Widget child, {
      bool head = false,
    }) => Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: option.recommended ? LdsColors.primaryRow : null,
          border: head && option.recommended
              ? const Border(
                  top: BorderSide(color: LdsColors.primary, width: 3),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LdsSpace.tableCellX,
          vertical: 10,
        ),
        alignment: Alignment.center,
        child: DefaultTextStyle.merge(
          style: _valueStyle,
          textAlign: TextAlign.center,
          child: child,
        ),
      ),
    );
    Widget line(String label, List<Widget> cells, {bool head = false}) =>
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: head ? 48 : 44),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LabelCell(label, width: labelWidth),
                for (final (i, option) in options.indexed)
                  optionCell(option, cells[i], head: head),
              ],
            ),
          ),
        );
    return _TableFrame(
      rows: [
        line('항목', [
          for (final option in options)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.recommended) ...[
                  const LdsTag('추천', style: LdsTagStyle.solid),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option.marker != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: option.marker,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        option.title,
                        textAlign: TextAlign.center,
                        style: _labelStyle.copyWith(
                          fontSize: 15,
                          color: LdsColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (option.caption != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    option.caption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.mutedStrong,
                    ),
                  ),
                ],
              ],
            ),
        ], head: true),
        for (final row in rows) line(row.label, row.values),
      ],
    );
  }
}

/// 목록 표 가장 최근 줄의 '최신' 라벨.
class LdsLatestTag extends StatelessWidget {
  const LdsLatestTag({super.key});

  @override
  Widget build(BuildContext context) => const LdsTag('최신');
}

/// 숫자 700 + 단위 400 (9.2 예: **5,000**원/kg).
class LdsNumberUnit extends StatelessWidget {
  const LdsNumberUnit(this.number, this.unit, {super.key});

  final String number, unit;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: number,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: unit),
      ],
    ),
    style: _valueStyle,
  );
}
