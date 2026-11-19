import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_row_text.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/task_status_colors.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/task_row.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_icons.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

WorkCase _case({
  String title = "한라푸드",
  String status = "Running",
  String step = "WAITING_REPLY",
  String message = "거래처 회신 대기",
  ReplySummary? replies,
}) => WorkCase(
  id: "c1",
  initialMailId: "m1",
  title: title,
  sender: "sales@halla.example",
  senderName: "한라푸드 영업",
  receivedAt: "2026-10-19T02:10:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: message,
  inputRevision: 1,
  attachmentCount: 0,
  replySummary: replies,
);

Future<void> _pump(
  WidgetTester tester,
  Widget row, {
  double width = 400,
  double textScale = 1,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: row),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group("row text (SSOT 7.13)", () {
    test("party: registered supplier, its sender, or 후보 N곳", () {
      expect(taskPartyOf(_case()), "한라푸드");
      // Not registered yet: the title is the sender's address.
      expect(taskPartyOf(_case(title: "sales@halla.example")), "한라푸드 영업");
      expect(
        taskPartyOf(
          _case(
            title: "buyer@example.invalid",
            replies: const ReplySummary(requested: 3, responded: 1),
          ),
        ),
        "후보 3곳",
      );
      // One quote request is not a choice between candidates.
      expect(
        taskPartyOf(
          _case(
            title: "sales@halla.example",
            replies: const ReplySummary(requested: 1, responded: 0),
          ),
        ),
        "한라푸드 영업",
      );
    });

    test("detail is the step text until the list carries the subject", () {
      expect(taskDetailOf(_case()), "거래처 회신 대기");
      expect(
        taskDetailOf(_case(step: "WAITING_APPROVAL", message: "")),
        "발송 승인 대기",
      );
    });

    test("subject rule: [머리말] is the type, the rest the detail", () {
      expect(requestTypeOf("[단가변경] 냉동 딸기 1kg 단가 조정"), "단가변경 · 냉동 딸기 1kg 단가 조정");
      expect(requestTypeOf("  [견적 요청]  "), "견적 요청");
      expect(requestTypeOf("11월 공급 단가 안내"), "11월 공급 단가 안내");
    });

    test("progress shows n/5 or nothing", () {
      expect(taskProgressText(4), "4/5");
      expect(taskProgressText(null), "");
    });
  });

  testWidgets("one 48px line: store icon + party, step name, filled label", (
    tester,
  ) async {
    await _pump(tester, TaskRow(_case(), selected: false, onTap: () {}));
    expect(tester.getSize(find.byType(TaskRow)).height, TaskRow.height);
    expect(find.text("한라푸드"), findsOneWidget);
    // The step name instead of the request detail and n/5.
    expect(find.text("견적 요청·회신"), findsOneWidget);
    expect(find.text("거래처 회신 대기"), findsNothing);
    expect(find.text("4/5"), findsNothing);
    expect(find.text("진행 중"), findsOneWidget);
    // The store icon starts on the item name's line.
    expect(
      tester.getTopLeft(find.byType(AppIconView)).dx -
          tester.getTopLeft(find.byType(TaskRow)).dx,
      TaskRow.start,
    );
    final party = tester.widget<Text>(find.text("한라푸드"));
    expect(party.style!.fontSize, 15);
    expect(party.style!.fontWeight, FontWeight.w400);
    // 진행 중 = Dashboard와 같은 노랑 + 먹색 글자.
    final label = tester.widget<Text>(find.text("진행 중"));
    expect(label.style!.color, LdsColors.ink);
    expect(taskRowLabelColors(TaskLabel.running), (
      LdsColors.warning,
      LdsColors.ink,
    ));
    expect(taskRowLabelColors(TaskLabel.hold), (
      LdsColors.primary,
      Colors.white,
    ));
    // 완료 = #161716 + 흰 글자.
    expect(taskRowLabelColors(TaskLabel.done), (
      const Color(0xFF161716),
      Colors.white,
    ));
    // 라벨 바탕은 Dashboard 상태 색과 같습니다.
    expect(
      taskRowLabelColors(TaskLabel.running).$1,
      TaskStatusColors.ofGroup(TaskGroup.running),
    );
    expect(
      taskRowLabelColors(TaskLabel.done).$1,
      TaskStatusColors.ofGroup(TaskGroup.complete),
    );
    expect(
      taskRowLabelColors(TaskLabel.waiting).$1,
      TaskStatusColors.ofGroup(TaskGroup.confirm),
    );
    // Sender and time are kept for the screen reader.
    expect(
      tester.getSemantics(find.byType(TaskRow)).label,
      contains("한라푸드 영업"),
    );
  });

  testWidgets("a selected row is gray with a dark bar and a bold name", (
    tester,
  ) async {
    await _pump(tester, TaskRow(_case(), selected: true, onTap: () {}));
    final material = tester.widget<Material>(
      find
          .descendant(of: find.byType(TaskRow), matching: find.byType(Material))
          .first,
    );
    expect(material.color, TaskRow.selectedColor);
    final bar = find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == TaskRow.selectedBar,
    );
    expect(tester.getSize(bar), const Size(3, TaskRow.height));
    expect(
      tester.widget<Text>(find.text("한라푸드")).style!.fontWeight,
      FontWeight.w700,
    );
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets("nothing overflows at the narrowest list, scale $scale", (
      tester,
    ) async {
      for (final (status, step) in [
        ("Waiting", "PENDING_START"),
        ("Running", "WAITING_REPLY"),
        ("Pending", "ON_HOLD"),
        ("Pending", "FAILED"),
      ]) {
        await _pump(
          tester,
          TaskRow(
            _case(
              title: "아주 긴 이름의 거래처 주식회사",
              status: status,
              step: step,
              message: "아주 긴 단계 설명이 들어와도 한 줄로 줄여야 합니다",
            ),
            selected: false,
            onTap: () {},
          ),
          width: 400 - 2,
          textScale: scale,
        );
        expect(tester.takeException(), isNull, reason: "$status/$step");
      }
    });
  }

  testWidgets("row content sits in the vertical middle of the 48px row", (
    tester,
  ) async {
    await _pump(tester, TaskRow(_case(), selected: true, onTap: () {}));
    final row = tester.getRect(find.byType(TaskRow));
    expect(row.height, TaskRow.height);
    final party = tester.getRect(find.text("한라푸드"));
    expect(party.center.dy, closeTo(row.center.dy, 1));
    final label = tester.getRect(find.byType(TaskStatusLabel));
    expect(label.center.dy, closeTo(row.center.dy, 1));
  });

  testWidgets("status label hugs its text inside a Wrap (detail header)", (
    tester,
  ) async {
    await _pump(
      tester,
      const Wrap(children: [TaskStatusLabel(TaskLabel.running)]),
      width: 800,
    );
    final width = tester.getSize(find.byType(TaskStatusLabel)).width;
    expect(width, greaterThanOrEqualTo(64));
    expect(width, lessThan(100));
  });
}
