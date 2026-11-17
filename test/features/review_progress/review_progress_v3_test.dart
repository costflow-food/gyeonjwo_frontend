import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/review_progress/domain/review_phase.dart";
import "package:gyeonjwo_frontend/features/review_progress/domain/review_progress_state.dart";
import "package:gyeonjwo_frontend/features/review_progress/presentation/widgets/review_progress_body.dart";
import "package:gyeonjwo_frontend/features/review_progress/presentation/widgets/review_progress_dialog.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

ReviewProgress _state(String step) => ReviewProgress(
  progress: CaseProgress(
    caseId: "c1",
    status: "Running",
    processingStep: step,
    inputRevision: 1,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  ReviewProgress state, {
  VoidCallback? onClose,
  VoidCallback? onViewCase,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: ReviewProgressDialog(
          title: "[단가 인상 안내] 깐양파 10kg",
          outcome: state.outcome,
          onClose: onClose ?? () {},
          onViewCase: onViewCase ?? () {},
          body: ReviewProgressBody(state: state, onRetry: () {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets("v3 frame: summary, guidance, horizontal steps, footer", (
    tester,
  ) async {
    await _pump(tester, _state("SELECTING_CANDIDATES"));
    expect(find.byType(LdsDialog), findsOneWidget);
    expect(find.text("검토 진행"), findsOneWidget);
    // Summary: 2 of 4, the running stage and what comes next.
    expect(find.text("2/4"), findsOneWidget);
    expect(find.text("다음 · 회신 검토"), findsOneWidget);
    expect(find.byType(LdsNotice), findsOneWidget);
    expect(find.text("창을 닫아도 검토는 서버에서 계속됩니다."), findsOneWidget);
    expect(find.widgetWithText(LdsButton, "닫기"), findsOneWidget);
    // Not in v3: extracted request info, found candidates, notify toggle.
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(LdsToggle), findsNothing);
    expect(find.textContaining("알림"), findsNothing);
    expect(find.textContaining("추출한"), findsNothing);
    expect(find.textContaining("찾은 후보"), findsNothing);
  });

  testWidgets("step bar: done, current and upcoming follow the stage", (
    tester,
  ) async {
    await _pump(tester, _state("SELECTING_CANDIDATES"));
    final bar = tester.widget<LdsStepBar>(find.byType(LdsStepBar));
    expect(bar.steps.map((step) => step.label), [
      for (final stage in ReviewStage.values) stage.label,
    ]);
    expect(bar.current, 1);
    expect(bar.stateOf(0), LdsStepState.done);
    expect(bar.stateOf(1), LdsStepState.current);
    expect(bar.stateOf(2), LdsStepState.upcoming);
    expect(bar.steps[0].caption, "완료");
    expect(bar.steps[1].caption, "진행 중");
    expect(bar.steps[3].caption, isNull);
  });

  testWidgets("review ready: every step done, 닫기 opens the case", (
    tester,
  ) async {
    var viewed = 0;
    await _pump(tester, _state("REVIEW_READY"), onViewCase: () => viewed++);
    final bar = tester.widget<LdsStepBar>(find.byType(LdsStepBar));
    expect(bar.current, ReviewStage.values.length);
    expect(List.generate(4, bar.stateOf), everyElement(LdsStepState.done));
    expect(find.text("4/4"), findsOneWidget);
    expect(find.text(ReviewOutcome.reviewReady.message), findsOneWidget);
    await tester.tap(find.widgetWithText(LdsButton, "닫기"));
    expect(viewed, 1);
  });

  testWidgets("a stop marks its stage '멈춤' with an error notice", (
    tester,
  ) async {
    await _pump(tester, _state("FAILED"));
    final bar = tester.widget<LdsStepBar>(find.byType(LdsStepBar));
    expect(bar.steps[bar.current!].caption, "멈춤");
    final notice = tester.widget<LdsNotice>(find.byType(LdsNotice));
    expect(notice.tone, LdsNoticeTone.error);
  });

  testWidgets("while running, 닫기 only closes", (tester) async {
    var closed = 0, viewed = 0;
    await _pump(
      tester,
      _state("EXTRACTING"),
      onClose: () => closed++,
      onViewCase: () => viewed++,
    );
    await tester.tap(find.widgetWithText(LdsButton, "닫기"));
    expect((closed, viewed), (1, 0));
  });
}
