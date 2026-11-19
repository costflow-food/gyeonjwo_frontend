import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../lds_colors.dart';
import 'lds_button.dart';
import 'lds_focus_ring.dart';
import 'lds_metrics.dart';
import 'lds_popover.dart';
import 'lds_tab_bar.dart';

/// 날짜만(시각 0시).
DateTime ldsDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// `yyyy. M. d - yyyy. M. d`(하루면 날짜 하나).
String formatLdsDateRange(DateTimeRange range) {
  String day(DateTime d) => '${d.year}. ${d.month}. ${d.day}';
  return DateUtils.isSameDay(range.start, range.end)
      ? day(range.start)
      : '${day(range.start)} - ${day(range.end)}';
}

/// 빠른 선택(오늘 / 이번 주 / 이번 달). 영업일 기준: 이번 주 = 월~금
/// (주말에 고르면 그 주의 월~금), 이번 달 = 첫 평일~마지막 평일.
enum LdsQuickRange {
  today('오늘'),
  thisWeek('이번 주'),
  thisMonth('이번 달');

  const LdsQuickRange(this.label);

  final String label;

  DateTimeRange rangeFor(DateTime today) {
    final t = ldsDateOnly(today);
    return switch (this) {
      LdsQuickRange.today => DateTimeRange(start: t, end: t),
      LdsQuickRange.thisWeek => DateTimeRange(
        start: DateTime(t.year, t.month, t.day - (t.weekday - 1)),
        end: DateTime(t.year, t.month, t.day - (t.weekday - 1) + 4),
      ),
      LdsQuickRange.thisMonth => DateTimeRange(
        start: _businessDayFrom(DateTime(t.year, t.month), 1),
        end: _businessDayFrom(DateTime(t.year, t.month + 1, 0), -1),
      ),
    };
  }

  /// [day]가 주말이면 [step](1: 다음, -1: 이전) 쪽 가장 가까운 평일.
  static DateTime _businessDayFrom(DateTime day, int step) {
    var d = day;
    while (d.weekday > DateTime.friday) {
      d = DateTime(d.year, d.month, d.day + step);
    }
    return d;
  }
}

/// 기간 선택 단추 — LIKELION DateInput(range) (`docs/design-ssot.md` 7.9.2).
///
/// `yyyy. M. d - yyyy. M. d` 글자만(달력 아이콘 없음). 높이 36, 모서리 4, 테두리
/// `#D1D6DC`, hover `#333D4B`. 누르면 단추 오른쪽 끝에 맞춘 팝오버(달력 2개),
/// 744px 미만은 아래에서 올라오는 시트(달력 1개). 확정은 '적용'.
class LdsDateRangeButton extends StatefulWidget {
  const LdsDateRangeButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.today,
    this.iconOnly = false,
    this.invoice = false,
  });

  final bool iconOnly, invoice;
  final DateTimeRange value;
  final ValueChanged<DateTimeRange> onChanged;

  /// 없으면 지금 날짜.
  final DateTime? today;

  /// 이 폭 미만은 시트(달력 1개).
  static const sheetWidth = 744.0;

  @override
  State<LdsDateRangeButton> createState() => _LdsDateRangeButtonState();
}

class _LdsDateRangeButtonState extends State<LdsDateRangeButton> {
  final _focus = FocusNode(debugLabel: 'date range button');
  bool _hover = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final today = ldsDateOnly(widget.today ?? DateTime.now());
    final sheet =
        MediaQuery.sizeOf(context).width < LdsDateRangeButton.sheetWidth;
    DateTimeRange? picked;
    if (sheet) {
      picked = await showModalBottomSheet<DateTimeRange>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LdsRadius.dialog),
          ),
        ),
        builder: (context) => SafeArea(
          child: Center(
            heightFactor: 1,
            child: LdsDateRangePanel(
              initial: widget.value,
              today: today,
              months: 1,
              invoice: widget.invoice,
            ),
          ),
        ),
      );
    } else {
      picked = await Navigator.of(context).push(
        LdsPopoverRoute<DateTimeRange>(
          anchor: LdsPopoverRoute.anchorOf(context),
          label: '기간 선택 닫기',
          alignEnd: !widget.invoice,
          child: LdsDateRangePanel(
            initial: widget.value,
            today: today,
            months: widget.invoice ? 1 : 2,
            invoice: widget.invoice,
          ),
        ),
      );
    }
    if (!mounted) return;
    // 닫히면 초점을 단추로 돌려줍니다.
    _focus.requestFocus();
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iconOnly) {
      return LdsIconButton(
        icon: Icons.calendar_today_outlined,
        tooltip: '기간 선택, ${formatLdsDateRange(widget.value)}',
        onPressed: _open,
      );
    }
    final radius = BorderRadius.circular(LdsRadius.button);
    final label = formatLdsDateRange(widget.value);
    return Semantics(
      button: true,
      label: '기간 선택, $label',
      excludeSemantics: true,
      onTap: _open,
      child: LdsFocusRing(
        radius: LdsRadius.button,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: _hover ? LdsColors.title : LdsColors.borderStrong,
            ),
          ),
          child: InkWell(
            focusNode: _focus,
            onTap: _open,
            onHover: (hover) => setState(() => _hover = hover),
            borderRadius: radius,
            hoverColor: Colors.transparent,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // 달력 아이콘 없이 기간 글자만(필터·정렬 단추와 같은 글자 상자).
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: LdsText.control,
                        height: 1.2,
                        letterSpacing: -.3,
                        color: LdsColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
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

/// 기간 고르기 창 내용 (7.9.2): 빠른 선택 → 달력 [months]개 → 고른 기간 +
/// 취소·적용. '적용'하면 고른 기간으로 창을 닫습니다(pop).
class LdsDateRangePanel extends StatefulWidget {
  const LdsDateRangePanel({
    super.key,
    required this.initial,
    required this.today,
    this.months = 2,
    this.invoice = false,
  });

  final DateTimeRange initial;
  final DateTime today;

  /// 1(시트) 또는 2(팝오버: 이번 달·다음 달).
  final int months;
  final bool invoice;

  /// 달력 하나 폭, 달력 사이.
  static const monthWidth = 272.0;
  static const monthGap = 24.0;

  @override
  State<LdsDateRangePanel> createState() => _LdsDateRangePanelState();
}

class _LdsDateRangePanelState extends State<LdsDateRangePanel> {
  late DateTime? _start = ldsDateOnly(widget.initial.start);
  late DateTime? _end = ldsDateOnly(widget.initial.end);
  late DateTime _month = DateTime(
    widget.invoice ? widget.today.year : widget.initial.start.year,
    widget.invoice ? widget.today.month : widget.initial.start.month,
  );
  LdsQuickRange? _quick;

  @override
  void initState() {
    super.initState();
    _quick = _quickOf();
  }

  LdsQuickRange? _quickOf() {
    for (final quick in LdsQuickRange.values) {
      final range = quick.rangeFor(widget.today);
      if (range.start == _start && range.end == _end) return quick;
    }
    return null;
  }

  void _pickQuick(LdsQuickRange? quick) {
    if (quick == null) return;
    final range = quick.rangeFor(widget.today);
    setState(() {
      _quick = quick;
      _start = range.start;
      _end = range.end;
      _month = DateTime(range.start.year, range.start.month);
    });
  }

  /// 처음 누르면 시작, 다음에 누르면 끝(시작보다 앞이면 시작을 다시).
  void _pickDay(DateTime day) => setState(() {
    final start = _start;
    if (start == null || _end != null || day.isBefore(start)) {
      _start = day;
      _end = null;
    } else {
      _end = day;
    }
    _quick = _quickOf();
  });

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _apply() =>
      Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end!));

  @override
  Widget build(BuildContext context) {
    final start = _start;
    final end = _end;
    final summary = start == null
        ? '시작 날짜를 고르세요'
        : end == null
        ? '${formatLdsDateRange(DateTimeRange(start: start, end: start))} - 끝 날짜를 고르세요'
        : formatLdsDateRange(DateTimeRange(start: start, end: end));
    final calendars = [
      for (var i = 0; i < widget.months; i++)
        _MonthCalendar(
          month: DateTime(_month.year, _month.month + i),
          start: start,
          end: end,
          today: ldsDateOnly(widget.today),
          onPick: _pickDay,
          onPrevious: i == 0 ? () => _shiftMonth(-1) : null,
          onNext: i == widget.months - 1 ? () => _shiftMonth(1) : null,
        ),
    ];
    // 내용 폭 = 달력 폭(구분선이 화면 끝까지 늘지 않게).
    final width =
        LdsDateRangePanel.monthWidth * widget.months +
        LdsDateRangePanel.monthGap * (widget.months - 1);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: FocusScope(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.invoice)
                  LdsRoundTabs<LdsQuickRange?>(
                    tabs: [
                      for (final quick in LdsQuickRange.values)
                        LdsTabItem(value: quick, label: quick.label),
                    ],
                    selected: _quick,
                    onSelected: _pickQuick,
                  ),
                if (!widget.invoice) const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, calendar) in calendars.indexed) ...[
                      if (index > 0)
                        const SizedBox(width: LdsDateRangePanel.monthGap),
                      calendar,
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: LdsColors.line),
                const SizedBox(height: 16),
                SizedBox(
                  width: width,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 15,
                            letterSpacing: -.3,
                            color: LdsColors.title,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LdsButton(
                            label: '취소',
                            size: LdsButtonSize.large,
                            variant: LdsButtonVariant.outlinedNeutral,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 8),
                          LdsButton(
                            label: '적용',
                            size: LdsButtonSize.large,
                            onPressed: start != null && end != null
                                ? _apply
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 달력 한 달: 머리 `2026. 11` 17/700 + 이전/다음 24, 요일 일~토 13
/// `#8A95A0`, 날짜 15 · 36 원. 오늘 = 연한 원 + 아래 주황 점 4, 시작·끝 =
/// 주황 원·흰 글자, 사이 = `#FFEFE5` 띠.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.start,
    required this.end,
    required this.today,
    this.onPick,
    this.onPrevious,
    this.onNext,
  });

  final DateTime month;
  final DateTime? start;
  final DateTime? end;
  final DateTime today;

  /// 없으면 보기 전용: 날짜를 누를 수 없고 오늘만 주황 글자 + 연주황 원.
  final ValueChanged<DateTime>? onPick;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = DateTime(month.year, month.month).weekday % 7;
    final weeks = ((lead + days) / 7).ceil();
    return SizedBox(
      width: LdsDateRangePanel.monthWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  tooltip: '이전 달',
                  onPressed: onPrevious,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${month.year}. ${month.month}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                        color: LdsColors.ink,
                      ),
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  tooltip: '다음 달',
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final weekday in _weekdays)
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: Center(
                      child: ExcludeSemantics(
                        child: Text(
                          weekday,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LdsColors.outline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var week = 0; week < weeks; week++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: _cell(week * 7 + col - lead + 1, days)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int dayNumber, int days) {
    if (dayNumber < 1 || dayNumber > days) {
      return const SizedBox(height: _DayCell.height);
    }
    final day = DateTime(month.year, month.month, dayNumber);
    final pick = onPick;
    if (pick == null) {
      return _ViewDayCell(day: day, today: DateUtils.isSameDay(day, today));
    }
    final start = this.start;
    final end = this.end;
    final isStart = start != null && DateUtils.isSameDay(day, start);
    final isEnd = end != null && DateUtils.isSameDay(day, end);
    final inside =
        start != null && end != null && day.isAfter(start) && day.isBefore(end);
    final ranged = start != null && end != null && start != end;
    return _DayCell(
      day: day,
      edge: isStart || isEnd,
      bandLeft: inside || (ranged && isEnd),
      bandRight: inside || (ranged && isStart),
      today: DateUtils.isSameDay(day, today),
      onTap: () => pick(day),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox(width: 24);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        onTap: onPressed,
        child: LdsFocusRing(
          radius: LdsRadius.button,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(LdsRadius.button),
            child: SizedBox.square(
              dimension: 24,
              child: Icon(icon, size: 20, color: LdsColors.title),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.edge,
    required this.bandLeft,
    required this.bandRight,
    required this.today,
    required this.onTap,
  });

  static const height = 40.0;
  static const circle = 36.0;

  final DateTime day;

  /// 시작·끝.
  final bool edge;
  final bool bandLeft;
  final bool bandRight;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: edge || (bandLeft && bandRight),
    label:
        '${day.year}년 ${day.month}월 ${day.day}일'
        '${today ? ', 오늘' : ''}',
    excludeSemantics: true,
    onTap: onTap,
    child: SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 사이 띠: 칸 폭 전체, 시작·끝은 안쪽 절반만.
          Positioned.fill(
            top: (height - circle) / 2,
            bottom: (height - circle) / 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: bandLeft
                        ? LdsColors.primarySoft
                        : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: bandRight
                        ? LdsColors.primarySoft
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          LdsFocusRing(
            radius: circle / 2,
            child: Material(
              color: edge
                  ? LdsColors.primary
                  : today
                  ? LdsColors.canvas
                  : Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: circle,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1,
                          fontWeight: edge ? FontWeight.w700 : FontWeight.w400,
                          color: edge ? Colors.white : LdsColors.ink,
                        ),
                      ),
                      if (today)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: edge ? Colors.white : LdsColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 보기 전용 날짜 칸: 누를 수 없음. 오늘 = `#FFEFE5` 원 + 주황 700 글자.
class _ViewDayCell extends StatelessWidget {
  const _ViewDayCell({required this.day, required this.today});

  final DateTime day;
  final bool today;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${day.year}년 ${day.month}월 ${day.day}일'
        '${today ? ', 오늘' : ''}',
    excludeSemantics: true,
    child: SizedBox(
      height: _DayCell.height,
      child: Center(
        child: Container(
          width: _DayCell.circle,
          height: _DayCell.circle,
          alignment: Alignment.center,
          decoration: today
              ? const BoxDecoration(
                  color: LdsColors.primarySoft,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              height: 1,
              fontWeight: today ? FontWeight.w700 : FontWeight.w400,
              color: today ? LdsColors.primary : LdsColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 상단 바 날짜 확인 단추 (7.9.3 보완, 2026-11-18): 검색 왼쪽 36px 달력 아이콘.
///
/// 거르기 기능 없음. 누르면 단추 오른쪽 끝에 맞춘 팝오버(폭 320)에 이번 달
/// 달력 1개 + 이전·다음 달 넘기기. 오늘은 주황. 마우스를 올리면 '오늘
/// yyyy. M. d'. Esc·바깥 누르기로 닫습니다.
class LdsDateViewButton extends StatelessWidget {
  const LdsDateViewButton({super.key, this.today});

  /// 없으면 지금 날짜.
  final DateTime? today;

  static const panelWidth = 320.0;

  @override
  Widget build(BuildContext context) {
    final day = ldsDateOnly(today ?? DateTime.now());
    final label = '오늘 ${day.year}. ${day.month}. ${day.day}';
    return Builder(
      builder: (context) => LdsIconButton(
        icon: Icons.calendar_today_outlined,
        tooltip: label,
        onPressed: () => Navigator.of(context).push(
          LdsPopoverRoute<void>(
            anchor: LdsPopoverRoute.anchorOf(context),
            label: '날짜 확인 닫기',
            child: _DateViewPanel(today: day),
          ),
        ),
      ),
    );
  }
}

class _DateViewPanel extends StatefulWidget {
  const _DateViewPanel({required this.today});

  final DateTime today;

  @override
  State<_DateViewPanel> createState() => _DateViewPanelState();
}

class _DateViewPanelState extends State<_DateViewPanel> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  void _move(int step) =>
      setState(() => _month = DateTime(_month.year, _month.month + step));

  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    namesRoute: true,
    label: '날짜 확인',
    child: Container(
      width: LdsDateViewButton.panelWidth,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: _MonthCalendar(
        month: _month,
        start: null,
        end: null,
        today: widget.today,
        onPrevious: () => _move(-1),
        onNext: () => _move(1),
      ),
    ),
  );
}
