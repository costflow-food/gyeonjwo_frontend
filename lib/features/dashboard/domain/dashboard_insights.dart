/// 월별 처리 추세의 한 항목(접수 · 견적 요청 · 발송 · 보류 · 지연).
/// 최근 12개월 고정, 위쪽 기간 선택과 관계없습니다(`docs/design-ssot.md` 7.9.2).
class TrendSeries {
  const TrendSeries({
    required this.name,
    required this.thisYear,
    required this.lastYear,
  });

  final String name;

  /// 1월~12월, 12개.
  final List<int> thisYear;

  /// 지난해 같은 달, 12개.
  final List<int> lastYear;

  int get latest => thisYear.last;
}

/// 품목별 구매 비중 한 줄. 위쪽 기간을 따릅니다(7.9.2).
class CategoryShare {
  const CategoryShare({
    required this.name,
    required this.amount,
    required this.percent,
    required this.prevPercent,
  });

  final String name;

  /// 원.
  final int amount;

  /// 이번 기간 비중 %.
  final int percent;

  /// 직전 기간 비중 %.
  final int prevPercent;
}

class CategoryShareSummary {
  const CategoryShareSummary({
    required this.total,
    required this.changePercent,
    required this.items,
  });

  /// 기간 합계(원).
  final int total;

  /// 직전 기간 대비 증감 %. 음수 = 절감.
  final int changePercent;

  /// 비중이 큰 순서.
  final List<CategoryShare> items;
}

/// 시연용 예시 데이터(디자인 시안 값 그대로).
///
/// TODO(backend): 추세·품목 비중 API가 아직 없습니다. API가 생기면 응답으로
/// 바꿉니다. 데이터 출처·필드명은 백엔드와 확정이 필요합니다.
abstract final class DashboardSample {
  static const trends = <TrendSeries>[
    TrendSeries(
      name: "접수",
      thisYear: [29, 15, 19, 6, 21, 23, 18, 30, 33, 24, 26, 27],
      lastYear: [24, 13, 17, 9, 16, 20, 17, 24, 27, 22, 21, 23],
    ),
    TrendSeries(
      name: "견적 요청",
      thisYear: [22, 11, 14, 5, 15, 17, 13, 22, 25, 18, 19, 20],
      lastYear: [18, 10, 12, 7, 12, 14, 12, 18, 20, 16, 15, 17],
    ),
    TrendSeries(
      name: "발송",
      thisYear: [18, 9, 12, 4, 13, 14, 11, 19, 21, 15, 16, 17],
      lastYear: [15, 8, 10, 5, 10, 12, 10, 15, 17, 13, 13, 14],
    ),
    TrendSeries(
      name: "보류",
      thisYear: [2, 1, 3, 1, 2, 1, 2, 3, 2, 1, 2, 1],
      lastYear: [3, 2, 2, 2, 3, 2, 1, 2, 3, 2, 2, 2],
    ),
    TrendSeries(
      name: "지연",
      thisYear: [6, 4, 7, 3, 8, 9, 6, 11, 12, 8, 10, 9],
      lastYear: [8, 6, 8, 5, 9, 10, 8, 12, 13, 10, 11, 11],
    ),
  ];

  static const share = CategoryShareSummary(
    total: 44532400,
    changePercent: -8,
    items: [
      CategoryShare(
        name: "냉동 딸기",
        amount: 22266200,
        percent: 50,
        prevPercent: 52,
      ),
      CategoryShare(
        name: "깐마늘",
        amount: 13359720,
        percent: 30,
        prevPercent: 27,
      ),
      CategoryShare(
        name: "기타 품목",
        amount: 8906480,
        percent: 20,
        prevPercent: 21,
      ),
    ],
  );
}
