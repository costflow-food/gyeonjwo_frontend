import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/case_stage.dart";
import "../../domain/work_case.dart";

/// 업무 진행 단계 이름. 목록 행의 n/5와 같은 다섯 단계입니다([CaseStage]).
const caseStepLabels = caseStepNames;

/// 단계 바에만 쓰는 시안 색(토큰에 없음).
abstract final class _StepColors {
  /// 끝난 단계 원·선.
  static const done = LdsColors.primary;

  /// 남은 단계 아이콘.
  static const todoIcon = LdsColors.outline;

  /// 오류 원·이름.
  static const error = Color(0xFFE12337);
}

/// 단계 원 안 아이콘: 접수 · 정보 추출 · 후보 찾기 · 견적 요청·회신 · 검토 카드
/// (시안의 Remix 아이콘과 비슷한 Material 아이콘).
const caseStepIcons = [
  Icons.inbox_outlined,
  Icons.find_in_page_outlined,
  Icons.storefront_outlined,
  Icons.swap_horiz,
  Icons.balance_outlined,
];

/// Tasks 상세 '진행 상황'의 가로 단계 바 (Tasks 시안, Tasks 전용).
///
/// 원 28: 끝난 단계 `#FF6000` + 체크, 지금 단계 `#FF6000` 32 + 연한 테두리,
/// 남은 단계 흰 원 + 회색 `#D1D6DC` 테두리 · `#8A95A0` 아이콘. 아이콘: 접수 받은편지함 ·
/// 정보 추출 문서 찾기 · 후보 찾기 가게 · 견적 요청·회신 주고받기 · 검토 카드 저울.
/// 오류면 지금 단계를 빨간 원 +
/// 오류 아이콘으로 그립니다. 이름 아래에는 다른 글을 두지 않습니다. 단계를
/// 모르면(모르는 단계 코드) 모두 남은 단계로 그립니다.
class CaseStepBar extends StatelessWidget {
  const CaseStepBar({super.key, required this.stage});

  final CaseStage? stage;

  static const _dot = 28.0;
  static const _bigDot = 32.0;

  /// 이보다 좁으면 처음·끝·지금 단계 이름만 보입니다.
  static const _allLabelsWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final stage = this.stage;
    final current = stage == null || stage.complete ? null : stage.index - 1;
    final complete = stage?.complete ?? false;
    final error = stage?.error ?? false;
    return Semantics(
      label: stage?.semanticsLabel ?? "진행 단계 확인 중",
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const count = CaseStage.total;
          double centerOf(int index) =>
              _dot / 2 + index * (width - _dot) / (count - 1);
          final allLabels = width >= _allLabelsWidth;
          return SizedBox(
            height: _dot + 6 + 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LinesPainter(
                      centers: [for (var i = 0; i < count; i++) centerOf(i)],
                      // 선 k(단계 k-1 → k)는 지금 단계까지 칠합니다.
                      doneUpTo: complete ? count - 1 : (current ?? 0),
                      y: _dot / 2,
                      gap: _dot / 2 + 6,
                    ),
                  ),
                ),
                for (var i = 0; i < count; i++) ...[
                  _positionedDot(
                    center: centerOf(i),
                    state: complete || (current != null && i < current)
                        ? _StepState.done
                        : i == current
                        ? (error ? _StepState.error : _StepState.now)
                        : _StepState.todo,
                    icon: caseStepIcons[i],
                  ),
                  if (allLabels || i == 0 || i == count - 1 || i == current)
                    _positionedLabel(
                      index: i,
                      count: count,
                      center: centerOf(i),
                      width: width,
                      state: i == current
                          ? (error ? _StepState.error : _StepState.now)
                          : _StepState.todo,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _positionedDot({
    required double center,
    required _StepState state,
    required IconData icon,
  }) {
    final big = state == _StepState.now || state == _StepState.error;
    final size = big ? _bigDot : _dot;
    final (background, border, ring, iconColor) = switch (state) {
      _StepState.done => (_StepColors.done, null, null, Colors.white),
      _StepState.now => (
        LdsColors.primary,
        null,
        LdsColors.primarySoft,
        Colors.white,
      ),
      _StepState.error => (
        _StepColors.error,
        null,
        LdsColors.errorBg,
        Colors.white,
      ),
      _StepState.todo => (
        Colors.white,
        LdsColors.borderStrong,
        null,
        _StepColors.todoIcon,
      ),
    };
    return Positioned(
      left: center - size / 2,
      top: (_dot - size) / 2,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: border == null ? null : Border.all(color: border, width: 2),
          boxShadow: ring == null
              ? null
              : [BoxShadow(color: ring, spreadRadius: 4)],
        ),
        alignment: Alignment.center,
        child: Icon(
          switch (state) {
            _StepState.done => Icons.check,
            _StepState.error => Icons.error_outline,
            _ => icon,
          },
          size: 16,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _positionedLabel({
    required int index,
    required int count,
    required double center,
    required double width,
    required _StepState state,
  }) {
    final style = TextStyle(
      fontSize: 11,
      height: 1.4,
      letterSpacing: -.3,
      fontWeight: state == _StepState.todo ? FontWeight.w400 : FontWeight.w600,
      color: switch (state) {
        _StepState.now => LdsColors.primary,
        _StepState.error => _StepColors.error,
        _ => LdsColors.muted,
      },
    );
    final text = Text(
      caseStepNames[index],
      maxLines: 1,
      softWrap: false,
      style: style,
    );
    const top = _dot + 6.0;
    // 처음은 왼쪽, 끝은 오른쪽에 맞추고 나머지는 원 가운데.
    if (index == 0) return Positioned(left: 0, top: top, child: text);
    if (index == count - 1) return Positioned(right: 0, top: top, child: text);
    const half = 60.0;
    return Positioned(
      left: center - half,
      width: half * 2,
      top: top,
      child: Center(child: text),
    );
  }
}

enum _StepState { done, now, error, todo }

/// 단계 사이 선: 끝난 쪽은 `#FF6000` 실선, 남은 쪽은 `#D1D6DC` 점선.
class _LinesPainter extends CustomPainter {
  const _LinesPainter({
    required this.centers,
    required this.doneUpTo,
    required this.y,
    required this.gap,
  });

  final List<double> centers;

  /// 이 단계(0부터)까지 이어지는 선은 끝난 선입니다.
  final int doneUpTo;
  final double y;

  /// 원 가운데에서 선이 시작하는 거리.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2;
    for (var k = 1; k < centers.length; k++) {
      final from = centers[k - 1] + gap;
      final to = centers[k] - gap;
      if (to <= from) continue;
      if (k <= doneUpTo) {
        paint.color = _StepColors.done;
        canvas.drawLine(Offset(from, y), Offset(to, y), paint);
      } else {
        paint.color = LdsColors.borderStrong;
        for (var x = from; x < to; x += 8) {
          canvas.drawLine(
            Offset(x, y),
            Offset((x + 4).clamp(from, to), y),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LinesPainter oldDelegate) =>
      oldDelegate.doneUpTo != doneUpTo ||
      oldDelegate.centers.length != centers.length ||
      oldDelegate.centers.lastOrNull != centers.lastOrNull;
}

/// 업무의 단계 바. 휴대폰 화면과 넓은 화면이 같이 씁니다.
class CaseProgressSteps extends StatelessWidget {
  const CaseProgressSteps({super.key, required this.workCase, this.stopCode});

  final WorkCase workCase;

  /// API-03 멈춘 이유 코드(있으면 멈춘 단계를 더 정확히 압니다).
  final String? stopCode;

  @override
  Widget build(BuildContext context) =>
      CaseStepBar(stage: caseStageOf(workCase, stopCode: stopCode));
}

/// '지금 할 일' 표의 한 줄: 이름표(136) · 값 · 오른쪽 덧말.
class TodoRow {
  const TodoRow(this.label, this.value, {this.note = "", this.warn = false});

  final String label;
  final String value;
  final String note;

  /// 덧말을 빨갛게(확인 필요·실패 등).
  final bool warn;
}

/// '지금 할 일' 상자 (Tasks 시안, `docs/design-ssot.md` 7.5).
///
/// 머리 = 상황 문장 + 오른쪽 [세부 상태 파란 라벨]과 개수. 아래 설명 → 작은
/// 이름표 → 표 → 오른쪽 정렬 버튼. 할 일이 없으면 버튼 대신 '지금은 하실
/// 일이 없어요.'를 둡니다. 상자 `#F9FAFB`, 1px `#E5E7EA`, 모서리 12, 안쪽 16/18.
class TodoBox extends StatelessWidget {
  const TodoBox({
    super.key,
    required this.title,
    this.tag,
    this.meta,
    this.description,
    this.tableLabel,
    this.rows = const [],
    this.body,
    this.actions = const [],
    this.leading,
    this.footer,
  });

  static const idleText = "지금은 하실 일이 없어요. 끝나면 알려 드릴게요.";

  final String title;

  /// 단계 안 세부 상태(파란 라벨).
  final String? tag;

  /// 개수·상태 글자(라벨 오른쪽).
  final String? meta;
  final String? description;
  final String? tableLabel;
  final List<TodoRow> rows;

  /// 표 대신 넣는 내용(업체 선택 목록 등).
  final Widget? body;

  /// 오른쪽 정렬 버튼. 비어 있으면 [idleText]를 보입니다.
  final List<Widget> actions;

  /// 버튼 줄 왼쪽 글자(예: 'n / N곳 선택').
  final Widget? leading;

  /// 버튼 아래 덧말·오류.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final description = this.description;
    return Semantics(
      container: true,
      label: "지금 할 일",
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: LdsColors.canvas,
          border: Border.all(color: LdsColors.line),
          borderRadius: BorderRadius.circular(LdsRadius.panel),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        letterSpacing: -.3,
                        color: LdsColors.ink,
                      ),
                    ),
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 12),
                  LdsTag(tag!, tone: LdsTagTone.progressing),
                ],
                if (meta != null) ...[
                  SizedBox(width: tag == null ? 12 : 8),
                  Text(
                    meta!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.muted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              ConstrainedBox(
                // 설명은 두 줄 자리를 늘 둡니다(상자 크기를 맞춤).
                constraints: const BoxConstraints(minHeight: 13 * 1.6 * 2),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    letterSpacing: -.3,
                    color: LdsColors.label,
                  ),
                ),
              ),
            ],
            if (tableLabel != null && (rows.isNotEmpty || body != null)) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  tableLabel!,
                  style: const TextStyle(fontSize: 12, color: LdsColors.muted),
                ),
              ),
              const SizedBox(height: 6),
            ] else if (rows.isNotEmpty || body != null)
              const SizedBox(height: 14),
            if (rows.isNotEmpty) TodoTable(rows: rows),
            ?body,
            const SizedBox(height: 14),
            _actionRow(),
            ?footer,
          ],
        ),
      ),
    );
  }

  Widget _actionRow() {
    final leading = this.leading;
    if (actions.isEmpty && leading == null) {
      return const SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            idleText,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: -.3,
              color: LdsColors.muted,
            ),
          ),
        ),
      );
    }
    // 버튼은 상자 오른쪽 끝에 붙입니다. 왼쪽 글자([leading], 'n / N곳 선택'
    // 같은 짧은 글)는 제 폭만 쓰고, 버튼이 남는 폭을 다 써서 좁으면 오른쪽
    // 정렬로 줄바꿈됩니다.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// '지금 할 일' 표: 흰 바탕, 1px `#E5E7EA`, 모서리 8. 줄 높이 44, 이름표 칸
/// 136(`#F9FAFB`, 14/600).
class TodoTable extends StatelessWidget {
  const TodoTable({super.key, required this.rows});

  final List<TodoRow> rows;

  static const labelWidth = 136.0;

  @override
  Widget build(BuildContext context) => Container(
    // 높이는 줄 수만큼(줄 44). 줄이 적어도 빈칸을 두지 않습니다.
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.table),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const Divider(height: 1, color: LdsColors.lineSoft),
          _row(row),
        ],
      ],
    ),
  );

  Widget _row(TodoRow row) => IntrinsicHeight(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: labelWidth,
            color: LdsColors.canvas,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.center,
            child: Text(
              row.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: LdsColors.label,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        letterSpacing: -.3,
                        color: LdsColors.title,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (row.note.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text(
                      row.note,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: row.warn
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: row.warn ? _StepColors.error : LdsColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Tasks 상세의 흰 카드(모서리 12): '진행 상황'·'받은 메일 · 근거 자료'.
/// 제목 17/600 아래 1px `#F3F4F6`, 오른쪽에 짧은 덧말(13 `#6B7583`).
class CaseSectionCard extends StatelessWidget {
  const CaseSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.panel),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LdsColors.lineSoft)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      letterSpacing: -.3,
                      color: LdsColors.ink,
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Text(
                  trailing!,
                  style: const TextStyle(fontSize: 13, color: LdsColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}
