import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/lds/lds.dart";

/// Dashboard 위쪽 기간(`docs/design-ssot.md` 7.9.2). 기본은 이번 주(일~토).
/// 품목별 구매 비중이 이 기간을 따릅니다(월별 처리 추세는 최근 12개월 고정).
final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriod, DateTimeRange>(DashboardPeriod.new);

class DashboardPeriod extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() => LdsQuickRange.thisWeek.rangeFor(DateTime.now());

  void select(DateTimeRange range) => state = range;
}
