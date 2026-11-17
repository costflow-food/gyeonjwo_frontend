import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/case_progress.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/work_case_panel.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

WorkCase _case(String status, String step, {String message = ""}) => WorkCase(
  id: "c1",
  initialMailId: "m1",
  title: "한라푸드",
  sender: "sales@halla.example",
  senderName: "한라푸드 영업",
  receivedAt: "2026-10-19T02:10:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: message,
  inputRevision: 1,
  attachmentCount: 0,
  itemName: "냉동 딸기",
);

class _Mail implements WorkQueueRepository {
  @override
  Future<OriginalMail> getOriginalMail(String mailId) async =>
      const OriginalMail(
        id: "m1",
        subject: "[단가인상] 냉동 딸기 IQF 홀 10kg 단가 조정",
        sender: "sales@halla.example",
        recipients: ["buyer@example.invalid"],
        receivedAt: "2026-10-19T02:10:00Z",
        bodyText: "11월 21일 출고분부터 단가를 조정하고자 합니다.",
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, WorkCase workCase) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = const Size(1100, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: WorkCasePanel(workCase: workCase),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workQueueRepositoryProvider.overrideWithValue(_Mail()),
        // A failed send may have drafts; this case has none.
        caseHasDraftsProvider("c1").overrideWith((ref) async => false),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LdsStepBar _bar(WidgetTester tester) =>
    tester.widget<LdsStepBar>(find.byType(LdsStepBar));

void main() {
  testWidgets("header, progress with 지금 할 일, then the mail", (tester) async {
    await _pump(
      tester,
      _case("Running", "WAITING_REPLY", message: "거래처 회신 대기"),
    );
    // Header: item, the mail subject, sender and time.
    expect(find.text("냉동 딸기"), findsOneWidget);
    expect(find.text("[단가인상] 냉동 딸기 IQF 홀 10kg 단가 조정"), findsOneWidget);
    expect(find.textContaining("한라푸드 영업 · "), findsOneWidget);
    expect(find.widgetWithText(LdsButton, "원문 보기"), findsOneWidget);
    // The quote requests went out: their drafts can be opened.
    expect(find.widgetWithText(LdsButton, "메일 초안"), findsOneWidget);

    // The five slices, on the third (견적 요청), with 지금 under it.
    final bar = _bar(tester);
    expect(bar.steps.map((step) => step.label), caseStepLabels);
    expect(bar.current, 2);
    expect(bar.steps[2].caption, "지금");
    expect(bar.steps[0].caption, "10.19 11:10");

    // 지금 할 일: the step's own state on the right of its head.
    expect(find.text("지금 할 일"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NowToDoBox),
        matching: find.widgetWithText(LdsTag, "거래처 회신 대기"),
      ),
      findsOneWidget,
    );
    // Its frame keeps the same minimum height on every case.
    final body = find
        .descendant(
          of: find.byType(NowToDoBox),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox &&
                widget.constraints.minHeight == NowToDoBox.minBodyHeight,
          ),
        )
        .first;
    expect(
      tester.getSize(body).height,
      greaterThanOrEqualTo(NowToDoBox.minBodyHeight),
    );

    // 받은 메일 below, without repeating the subject.
    expect(find.text("받은 메일"), findsOneWidget);
    expect(find.text("11월 21일 출고분부터 단가를 조정하고자 합니다."), findsOneWidget);
    expect(
      tester.getTopLeft(find.text("받은 메일")).dy,
      greaterThan(tester.getBottomLeft(find.byType(NowToDoBox)).dy),
    );
  });

  testWidgets("a drafted request offers 메일 초안 in the header", (tester) async {
    await _pump(tester, _case("Pending", "WAITING_APPROVAL"));
    expect(find.widgetWithText(LdsButton, "메일 초안"), findsOneWidget);
    // Not twice: the step box leaves it to the header.
    expect(find.text("메일 초안 보기"), findsNothing);
  });

  testWidgets("a case not started yet decides inside 지금 할 일", (tester) async {
    await _pump(tester, _case("Waiting", "PENDING_START"));
    expect(_bar(tester).current, 0);
    // Nothing drafted before the review starts.
    expect(find.widgetWithText(LdsButton, "메일 초안"), findsNothing);
    expect(
      find.descendant(
        of: find.byType(NowToDoBox),
        matching: find.text("다른 대안 찾기"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a failed case marks no step as current", (tester) async {
    await _pump(tester, _case("Pending", "FAILED"));
    expect(_bar(tester).current, isNull);
  });
}
