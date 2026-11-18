import "dart:math" as math;
import "dart:ui" show PathMetric;

import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/dashboard_insights.dart";
import "dashboard_card.dart";

/// 월별 처리 추세 카드 (`docs/design-ssot.md` 7.9.2).
///
/// 최근 12개월 고정이며 위쪽 기간과 관계없다는 것을 설명 줄에 적습니다.
/// 카드 안에 기간·단위 선택 박스를 두지 않습니다. 항목 칸(접수·견적 요청·
/// 발송·보류·지연)을 누르면 그래프가 그 항목으로 바뀝니다.
class MonthlyTrendCard extends StatefulWidget {
  const MonthlyTrendCard({
    super.key,
    required this.series,
    this.initialIndex = 0,
  });

  final List<TrendSeries> series;
  final int initialIndex;

  @override
  State<MonthlyTrendCard> createState() => _MonthlyTrendCardState();
}

class _MonthlyTrendCardState extends State<MonthlyTrendCard> {
  late int _selected = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final series = widget.series[_selected];
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardCardHeader(
            title: "월별 처리 추세",
            caption: "최근 12개월 · 위쪽 기간과 관계없이 표시해요. 항목을 누르면 그래프가 그 항목으로 바뀌어요.",
          ),
          const SizedBox(height: 16),
          _SeriesTabs(
            series: widget.series,
            selected: _selected,
            onSelect: (index) => setState(() => _selected = index),
          ),
          const SizedBox(height: 20),
          _Legend(series: series),
          const SizedBox(height: 8),
          _TrendChart(key: ValueKey(series.name), series: series),
        ],
      ),
    );
  }
}

/// 항목 칸: 이름 13 + 최근 달 값 19/700. 선택 = 연주황 바탕 + 주황 테두리.
/// 누르면 보이는 내용이 바뀌므로 탭입니다(7.6).
class _SeriesTabs extends StatelessWidget {
  const _SeriesTabs({
    required this.series,
    required this.selected,
    required this.onSelect,
  });

  final List<TrendSeries> series;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tab(int index) => _SeriesTab(
      series: series[index],
      selected: index == selected,
      onTap: () => onSelect(index),
    );

    if (isCompactLayout(context)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final minimumWidth =
              104 * MediaQuery.textScalerOf(context).scale(13) / 13;
          final columns = ((constraints.maxWidth + 8) / (minimumWidth + 8))
              .floor()
              .clamp(1, series.length);
          final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < series.length; index++)
                SizedBox(width: width, child: tab(index)),
            ],
          );
        },
      );
    }
    return Row(
      children: [
        for (var index = 0; index < series.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: tab(index)),
        ],
      ],
    );
  }
}

class _SeriesTab extends StatelessWidget {
  const _SeriesTab({
    required this.series,
    required this.selected,
    required this.onTap,
  });

  final TrendSeries series;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LdsRadius.table);
    return Semantics(
      selected: selected,
      button: true,
      label: "${series.name} 12월 ${series.latest}건",
      onTap: onTap,
      excludeSemantics: true,
      child: LdsFocusRing(
        radius: LdsRadius.table,
        child: Material(
          color: selected ? LdsColors.primarySoft : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? LdsColors.primary : LdsColors.line,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                // 칸 폭 전체(Expanded)를 채웁니다.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    series.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: dashText(
                      13,
                      FontWeight.w400,
                      selected ? LdsColors.primaryText : LdsColors.label,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${series.latest}건",
                    maxLines: 1,
                    style: dashText(19, FontWeight.w700, LdsColors.ink),
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

/// 범례: 주황 실선 '항목 건수 · 월별 (단위: 건)' + 회색 점선 '지난해',
/// 오른쪽 끝 '12월 N건'.
class _Legend extends StatelessWidget {
  const _Legend({required this.series});

  final TrendSeries series;

  @override
  Widget build(BuildContext context) {
    final sub = dashText(13, FontWeight.w400, LdsColors.label);
    return Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 28,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    decoration: BoxDecoration(
                      color: LdsColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    series.name,
                    style: dashText(13, FontWeight.w700, LdsColors.ink),
                  ),
                  const SizedBox(width: 6),
                  Text("건수 · 월별 (단위: 건)", style: sub),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 2,
                    child: CustomPaint(
                      painter: _HorizontalDashPainter(LdsColors.disabled),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("지난해", style: sub),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "12월 ", style: sub),
              TextSpan(
                text: "${series.latest}건",
                style: dashText(13, FontWeight.w700, LdsColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HorizontalDashPainter extends CustomPainter {
  const _HorizontalDashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 4, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HorizontalDashPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 꺾은선 그래프: 올해(주황 실선 2.2) + 지난해(회색 점선 2) + 가로 격자(점선)
/// + 마지막 달 점. 마우스를 올리거나 누르면 세로 안내선·점·말풍선
/// ('11월 · 접수 26건 / 지난해 21건').
///
/// 높이는 폭의 400/900입니다. 카드가 옆 카드와 높이를 맞출 수 있게(고유 높이)
/// LayoutBuilder 없이 그립니다.
class _TrendChart extends StatefulWidget {
  const _TrendChart({super.key, required this.series});

  final TrendSeries series;

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  int? _hover;
  Size? _size;
  final _chartKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _pick(Offset position) {
    final size = _chartKey.currentContext?.size;
    if (size == null) return;
    setState(() {
      _size = size;
      _hover = _ChartGeometry(size, widget.series).nearestIndex(position.dx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final base = DefaultTextStyle.of(context).style;
    final hover = _hover;
    final size = _size;
    final chart = AspectRatio(
      key: _chartKey,
      aspectRatio: 900 / 400,
      child: MouseRegion(
        onHover: (event) => _pick(event.localPosition),
        onExit: (_) => setState(() => _hover = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _pick(details.localPosition),
          child: Semantics(
            label:
                "${series.name} 월별 추세. "
                "${[for (var i = 0; i < 12; i++) "${i + 1}월 ${series.thisYear[i]}건"].join(", ")}",
            excludeSemantics: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrendPainter(series, hover, base),
                  ),
                ),
                if (hover != null && size != null)
                  _tooltip(_ChartGeometry(size, series), hover),
              ],
            ),
          ),
        ),
      ),
    );
    if (isCompactLayout(context)) {
      return Scrollbar(
        controller: _scrollController,
        thumbVisibility: false,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.horizontal,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(width: 600, child: chart),
        ),
      );
    }
    return chart;
  }

  Widget _tooltip(_ChartGeometry geometry, int index) {
    final series = widget.series;
    final point = geometry.point(index, series.thisYear[index]);
    const width = 148.0;
    final left = math.max(
      0.0,
      math.min(point.dx - width / 2, geometry.size.width - width),
    );
    final top = math.max(0.0, point.dy - 66);
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: LdsColors.ink,
            borderRadius: BorderRadius.circular(LdsRadius.table),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${index + 1}월 · ${series.name} ",
                      style: dashText(13, FontWeight.w400, Colors.white),
                    ),
                    TextSpan(
                      text: "${series.thisYear[index]}건",
                      style: dashText(13, FontWeight.w700, Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                "지난해 ${series.lastYear[index]}건",
                style: dashText(13, FontWeight.w400, LdsColors.borderStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartGeometry {
  _ChartGeometry(this.size, this.series) {
    final maxValue = [...series.thisYear, ...series.lastYear].reduce(math.max);
    // 항목마다 축 최댓값을 맞춥니다(보류처럼 작은 값도 모양이 보이게).
    step = _niceStep(maxValue * 1.15 / 5);
    final top = (maxValue * 1.15 / step).ceil() * step;
    yMax = top <= 0 ? step : top;
  }

  final Size size;
  final TrendSeries series;
  late final double step;
  late final double yMax;

  /// y축 글자.
  static const leftPad = 32.0;

  /// 월 글자.
  static const bottomPad = 26.0;
  static const topPad = 10.0;

  /// 1월·12월 점이 축선에 붙지 않게.
  static const sidePad = 12.0;

  Rect get plot =>
      Rect.fromLTRB(leftPad, topPad, size.width, size.height - bottomPad);

  double get _gap => (plot.width - sidePad * 2) / 11;

  double xOf(int index) => plot.left + sidePad + index * _gap;
  double yOf(num value) => plot.bottom - (value / yMax) * plot.height;
  Offset point(int index, num value) => Offset(xOf(index), yOf(value));

  int nearestIndex(double x) =>
      ((x - plot.left - sidePad) / _gap).round().clamp(0, 11);

  static double _niceStep(double rough) {
    if (rough <= 1) return 1;
    final magnitude = math
        .pow(10, (math.log(rough) / math.ln10).floor())
        .toDouble();
    final fraction = rough / magnitude;
    final nice = fraction <= 1
        ? 1
        : fraction <= 2
        ? 2
        : fraction <= 5
        ? 5
        : 10;
    return (nice * magnitude).toDouble();
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.series, this.hover, this.base);

  final TrendSeries series;
  final int? hover;

  /// 글꼴(테마)을 받아 축 글자에 씁니다.
  final TextStyle base;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _ChartGeometry(size, series);
    final plot = g.plot;
    final axisStyle = base.merge(
      dashText(13, FontWeight.w400, LdsColors.title, height: 1),
    );

    // 가로 격자 + y축 글자.
    final grid = Paint()
      ..color = LdsColors.line
      ..strokeWidth = 1;
    for (var value = g.step; value <= g.yMax + .001; value += g.step) {
      final y = g.yOf(value);
      _dashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(
        canvas,
        _format(value),
        Offset(plot.left - 8, y),
        axisStyle,
        alignRight: true,
      );
    }

    // 축선.
    final axis = Paint()
      ..color = LdsColors.borderStrong
      ..strokeWidth = 1;
    canvas
      ..drawLine(plot.bottomLeft, plot.bottomRight, axis)
      ..drawLine(plot.topLeft, plot.bottomLeft, axis);

    // 월 글자.
    for (var i = 0; i < 12; i++) {
      _text(
        canvas,
        "${i + 1}월",
        Offset(g.xOf(i), plot.bottom + 14),
        axisStyle,
        center: true,
      );
    }

    // 지난해(점선).
    final previous = Paint()
      ..color = LdsColors.borderStrong
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final previousPath = _smooth([
      for (var i = 0; i < 12; i++) g.point(i, series.lastYear[i]),
    ]);
    for (final metric in previousPath.computeMetrics()) {
      _dashMetric(canvas, metric, previous);
    }

    // 안내선.
    final hover = this.hover;
    if (hover != null) {
      final x = g.xOf(hover);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), axis);
    }

    // 올해(실선).
    final points = [
      for (var i = 0; i < 12; i++) g.point(i, series.thisYear[i]),
    ];
    canvas.drawPath(
      _smooth(points),
      Paint()
        ..color = LdsColors.primary
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 점: 기본은 마지막 달, 마우스를 올리면 그 달.
    final dot = points[hover ?? 11];
    canvas
      ..drawCircle(dot, 6, Paint()..color = Colors.white)
      ..drawCircle(dot, 4.5, Paint()..color = LdsColors.primary);
  }

  /// 시안과 같은 Catmull-Rom → 베지어(계수 1/6).
  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < p.length - 1; i++) {
      final a = p[math.max(i - 1, 0)];
      final b = p[i];
      final c = p[i + 1];
      final e = p[math.min(i + 2, p.length - 1)];
      path.cubicTo(
        b.dx + (c.dx - a.dx) / 6,
        b.dy + (c.dy - a.dy) / 6,
        c.dx - (e.dx - b.dx) / 6,
        c.dy - (e.dy - b.dy) / 6,
        c.dx,
        c.dy,
      );
    }
    return path;
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 6.0;
    final length = (b - a).distance;
    final direction = (b - a) / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      canvas.drawLine(
        a + direction * d,
        a + direction * math.min(d + dash, length),
        paint,
      );
    }
  }

  void _dashMetric(Canvas canvas, PathMetric metric, Paint paint) {
    const dash = 6.0;
    const gap = 6.0;
    for (var d = 0.0; d < metric.length; d += dash + gap) {
      canvas.drawPath(
        metric.extractPath(d, math.min(d + dash, metric.length)),
        paint,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    bool alignRight = false,
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? at.dx - painter.width
        : center
        ? at.dx - painter.width / 2
        : at.dx;
    painter
      ..paint(canvas, Offset(dx, at.dy - painter.height / 2))
      ..dispose();
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.hover != hover ||
      oldDelegate.series != series ||
      oldDelegate.base != base;
}
