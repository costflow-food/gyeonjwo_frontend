import "dart:ui" show PathMetric;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../app/app_paths.dart";
import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../../auth/presentation/gmail_connection_view_model.dart";
import "../../mail_intake/presentation/mail_intake_dialog.dart";
import "../../mail_intake/presentation/mail_intake_view_model.dart";
import "../../work_queue/domain/task_group.dart";
import "../../work_queue/presentation/completed_tasks_view_model.dart";
import "../../work_queue/presentation/widgets/gmail_read_notice.dart";
import "../../work_queue/presentation/work_queue_view_model.dart";
import "../domain/dashboard_insights.dart";
import "dashboard_period.dart";
import "widgets/category_share_card.dart";
import "widgets/monthly_trend_card.dart";

/// 상태 색 (`docs/design-ssot.md` 4.1): 확인 필요 주황, 진행 중 파랑, 완료 초록.
Color taskGroupColor(TaskGroup group) => switch (group) {
  TaskGroup.confirm => LdsColors.primary,
  TaskGroup.running => LdsColors.info,
  TaskGroup.complete => LdsColors.success,
};

/// Dashboard (`docs/design-ssot.md` 7.9, 7.9.1, 7.9.2, 7.9.3).
///
/// 위 '전체 업무' 한 줄 + 카드 4개(확인 필요 · 진행 중 · 완료 · 미분류 메일),
/// 아래 월별 처리 추세 + 품목별 구매 비중. 확인 필요·진행 중·완료 카드는 Tasks
/// 입구이고, 미분류는 접수·연결 확인 모달을 엽니다. 업무 목록·상태 탭·업무
/// 상세는 두지 않습니다.
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  /// 이 폭 미만에서는 상태 카드를 2×2로, 추세·비중 카드를 위아래로 놓습니다
  /// (7.9.1).
  static const twoByTwoWidth = 1100.0;

  /// 카드 사이.
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(workQueueViewModelProvider).value;
    // 검색과 무관한 건수. Tasks에서 검색 중이면 마지막 검색 없는 값입니다.
    final counts = queue?.allCounts;
    final completed = ref.watch(completedTasksViewModelProvider("")).value;
    final intake = ref.watch(mailIntakeViewModelProvider).value;
    final readDenied = ref.watch(gmailCapabilitiesProvider).readDenied;
    final byGroup = {
      TaskGroup.confirm: counts?.confirm,
      TaskGroup.running: counts?.running,
      TaskGroup.complete: completed?.total,
    };
    final total = byGroup.values.every((count) => count != null)
        ? byGroup.values.fold<int>(0, (sum, count) => sum + count!)
        : null;
    final wide = MediaQuery.sizeOf(context).width >= twoByTwoWidth;
    final cards = [
      for (final group in TaskGroup.values)
        _StatusCard(
          name: group.label,
          count: byGroup[group],
          dot: taskGroupColor(group),
          emphasized: group == TaskGroup.confirm,
          link: "보기 ›",
          onTap: () => context.go(AppPaths.tasksAt(tab: group.code)),
        ),
      _StatusCard.unsorted(
        count: intake?.totalPending,
        onTap: () => showMailIntakeDialog(context),
      ),
    ];
    return WorkspaceShell(
      topAction: LdsDateRangeButton(
        iconOnly: true,
        value: ref.watch(dashboardPeriodProvider),
        onChanged: ref.read(dashboardPeriodProvider.notifier).select,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (readDenied) ...[
            const GmailReadNotice(),
            const SizedBox(height: 16),
          ],
          _TotalBar(total: total, byGroup: byGroup),
          const SizedBox(height: _gap),
          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, card) in cards.take(3).indexed) ...[
                    if (index > 0) const SizedBox(width: _gap),
                    Expanded(child: card),
                  ],
                  // 미분류는 세로 점선 구분선 뒤(7.9.3).
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11.5),
                    child: _DashedLine(vertical: true),
                  ),
                  Expanded(child: cards.last),
                ],
              ),
            )
          else
            Column(
              children: [
                for (final row in [0, 2]) ...[
                  if (row > 0) const SizedBox(height: _gap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[row]),
                        const SizedBox(width: _gap),
                        Expanded(child: cards[row + 1]),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 24),
          // TODO(backend): 추세·품목 비중 API가 생기면 예시 데이터를 바꿉니다.
          if (wide)
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 19,
                    child: MonthlyTrendCard(series: DashboardSample.trends),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    flex: 10,
                    child: CategoryShareCard(
                      data: DashboardSample.share,
                      fill: true,
                    ),
                  ),
                ],
              ),
            )
          else ...const [
            MonthlyTrendCard(series: DashboardSample.trends),
            SizedBox(height: 24),
            CategoryShareCard(data: DashboardSample.share),
          ],
        ],
      ),
    );
  }
}

/// '전체 업무 N건' + 비율 막대(확인 필요·진행 중·완료). 범례 없음,
/// 미분류는 넣지 않습니다(7.9.3).
class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total, required this.byGroup});

  /// 비율 막대 두께(3. 비율 막대).
  static const barHeight = 12.0;

  final int? total;
  final Map<TaskGroup, int?> byGroup;

  @override
  Widget build(BuildContext context) {
    // 세 건수가 모두 올 때까지는 빈 막대입니다. 먼저 온 건수(완료)만으로
    // 그리면 잠깐 막대 전체가 초록이 됐다가 돌아옵니다.
    final parts = [
      if (total != null)
        for (final MapEntry(key: group, value: count) in byGroup.entries)
          if ((count ?? 0) > 0) (group, count!),
    ];
    return Semantics(
      container: true,
      label: total == null
          ? "전체 업무 불러오는 중"
          : [
              "전체 업무 $total건",
              for (final (group, count) in parts) "${group.label} $count건",
            ].join(", "),
      excludeSemantics: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LdsColors.line),
          borderRadius: BorderRadius.circular(LdsRadius.panel),
        ),
        child: Row(
          children: [
            const Text(
              "전체 업무",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: LdsColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            _CountText(count: total, numberSize: 23),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: _TotalBar.barHeight,
                child: parts.isEmpty
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: LdsColors.lineSoft,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (index, (group, count))
                              in parts.indexed) ...[
                            if (index > 0) const SizedBox(width: 4),
                            Expanded(
                              flex: count,
                              child: DecoratedBox(
                                key: ValueKey("bar-${group.code}"),
                                decoration: BoxDecoration(
                                  color: taskGroupColor(group),
                                  borderRadius: BorderRadius.circular(6),
                                ),
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
}

/// 상태 카드: 흰 바탕 + 1px `#E5E7EA`, 모서리 12, 최소 높이 112. 상태 이름
/// 15/700 + 앞 색 점 8, 숫자 32/700 + '건' 13/700, 오른쪽 아래 '보기 ›' 13
/// `#4E5968`. 설명 문장은 넣지 않습니다.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.name,
    required this.count,
    required this.dot,
    required this.emphasized,
    required this.link,
    required this.onTap,
  }) : unsorted = false;

  /// 미분류(7.9.1, 7.9.3): 회색 바탕 `#F3F4F6` + 점선 테두리 `#B1B8C0`,
  /// 회색 라벨 `#4E5968`. 상태 색을 쓰지 않습니다.
  const _StatusCard.unsorted({required this.count, required this.onTap})
    : name = "미분류",
      dot = null,
      emphasized = false,
      link = "확인 ›",
      unsorted = true;

  final String name;
  final int? count;
  final Color? dot;

  /// 확인 필요: 테두리 1.5px `#FF6000` + 바탕 `#FFF7F2`(라벨 없음).
  final bool emphasized;
  final String link;
  final VoidCallback onTap;
  final bool unsorted;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LdsRadius.panel);
    final background = unsorted
        ? LdsColors.lineSoft
        : emphasized
        ? LdsColors.primaryRow
        : Colors.white;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: unsorted ? LdsColors.label : LdsColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _CountText(
            count: count,
            numberSize: 32,
            color: unsorted ? LdsColors.label : LdsColors.ink,
          ),
          const SizedBox(height: 4),
          // 카드 높이가 같은 줄에서 맞춰져도 '보기 ›'는 오른쪽 아래에 둡니다.
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              link,
              style: const TextStyle(fontSize: 13, color: LdsColors.label),
            ),
          ),
        ],
      ),
    );
    final card = Material(
      color: background,
      shape: unsorted
          ? RoundedRectangleBorder(borderRadius: radius)
          : RoundedRectangleBorder(
              borderRadius: radius,
              side: emphasized
                  ? const BorderSide(color: LdsColors.primary, width: 1.5)
                  : const BorderSide(color: LdsColors.line),
            ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: unsorted
              ? CustomPaint(
                  foregroundPainter: const _DashedBorderPainter(
                    color: LdsColors.disabled,
                    radius: LdsRadius.panel,
                  ),
                  child: content,
                )
              : content,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: count == null
          ? "$name, 불러오는 중"
          : "$name $count건, ${unsorted ? "접수 확인" : "Tasks에서 보기"}",
      excludeSemantics: true,
      child: LdsFocusRing(radius: LdsRadius.panel, child: card),
    );
  }
}

/// 숫자(700) + ' 건'(13/700). 불러오는 중이면 숫자 없이 둡니다.
class _CountText extends StatelessWidget {
  const _CountText({
    required this.count,
    required this.numberSize,
    this.color = LdsColors.ink,
  });

  final int? count;
  final double numberSize;
  final Color color;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: count == null ? "" : "$count",
          style: TextStyle(
            fontSize: numberSize,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        TextSpan(
          text: " 건",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: color == LdsColors.ink ? LdsColors.title : color,
          ),
        ),
      ],
    ),
  );
}

/// 둥근 사각 점선 테두리 1px.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(radius),
        ),
      );
    _dash(canvas, path, color);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// 미분류 앞 세로 점선 구분선.
class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: vertical ? 1 : null,
    height: vertical ? null : 1,
    child: CustomPaint(painter: _DashedLinePainter(vertical: vertical)),
  );
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.vertical});

  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, vertical ? 0 : size.height / 2)
      ..lineTo(
        vertical ? size.width / 2 : size.width,
        vertical ? size.height : size.height / 2,
      );
    _dash(canvas, path, LdsColors.disabled);
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.vertical != vertical;
}

void _dash(Canvas canvas, Path path, Color color) {
  const dash = 4.0;
  const gap = 3.0;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  for (final PathMetric metric in path.computeMetrics()) {
    for (var distance = 0.0; distance < metric.length; distance += dash + gap) {
      canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
    }
  }
}
