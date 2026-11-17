import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log_filter.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log_state.dart";
import "package:gyeonjwo_frontend/features/workflow_log/presentation/widgets/workflow_log_detail.dart";
import "package:gyeonjwo_frontend/features/workflow_log/presentation/widgets/workflow_log_list.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

const _entries = [
  WorkflowLogEntry(
    id: "l1",
    createdAt: "2026-10-19T03:12:00Z",
    componentCode: "NODE",
    actorCode: "MAIL_SENDER",
    eventCode: "SEND_RESULT",
    summary: "다온신선푸드 추가 확인 메일 발송 결과를 확인하지 못함",
    outcome: LogOutcome.waiting,
    caseId: "c1",
    caseTitle: "[단가변경] 11월 냉동 딸기 공급단가 조정 안내",
    durationMs: 30000,
    toolName: "gmail.send",
    errorCode: "SEND_TIMEOUT",
  ),
  WorkflowLogEntry(
    id: "l2",
    createdAt: "2026-10-19T03:11:00Z",
    componentCode: "NODE",
    actorCode: "MAIL_SENDER",
    eventCode: "AUTO_SEND",
    summary: "자동 발송 시작",
    outcome: LogOutcome.success,
    caseId: "c1",
    caseTitle: "[단가변경] 11월 냉동 딸기 공급단가 조정 안내",
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 640,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const state = WorkflowLogState(
    filter: WorkflowLogFilter(),
    entries: _entries,
    total: 2,
    selectedId: "l1",
  );

  testWidgets("the log list is a list table: time, content, result tag", (
    tester,
  ) async {
    String? picked;
    await _pump(
      tester,
      WorkflowLogList(
        data: state,
        onSelect: (id) => picked = id,
        onLoadMore: () {},
      ),
    );
    final table = tester.widget<LdsListTable>(find.byType(LdsListTable));
    expect(table.columns.map((column) => column.label), ["시각", "내용", "결과"]);
    // yyyy.MM.dd HH:mm in Seoul time.
    expect(find.text("2026.10.19 12:12"), findsOneWidget);
    expect(
      find.widgetWithText(LdsTag, LogOutcome.waiting.label),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(LdsTag, LogOutcome.success.label),
      findsOneWidget,
    );
    // The chosen log is marked; a row opens its log.
    expect(table.rows.first.selected, isTrue);
    expect(table.rows.last.selected, isFalse);
    await tester.tap(find.text("자동 발송 시작"));
    expect(picked, "l2");
  });

  testWidgets("narrow: rows instead of the table, no overflow", (tester) async {
    await _pump(
      tester,
      WorkflowLogList(data: state, onSelect: (_) {}, onLoadMore: () {}),
      width: 340,
    );
    expect(find.byType(LdsListTable), findsNothing);
    expect(find.text("자동 발송 시작"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the detail is a label-value table with LDS buttons", (
    tester,
  ) async {
    await _pump(
      tester,
      WorkflowLogDetail(
        entry: _entries.first,
        caseFiltered: false,
        onFilterCase: (_, {caseTitle}) {},
      ),
      width: 520,
    );
    final table = find.byType(LdsKeyValueTable);
    expect(table, findsOneWidget);
    for (final label in ["시각", "업무", "소요 시간", "도구", "오류 코드", "사용한 근거"]) {
      expect(
        find.descendant(of: table, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(find.widgetWithText(LdsButton, "이 업무 로그만"), findsOneWidget);
    expect(find.widgetWithText(LdsButton, "업무 보기"), findsOneWidget);
    final tag = tester.widget<LdsTag>(find.byType(LdsTag));
    expect(tag.foreground, LdsColors.warningText);
  });
}
