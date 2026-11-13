import "dart:ui" show Tristate;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/queue_group_list.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/request_row.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/step_ring.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

WorkCase _case(
  String status,
  String step, {
  int revision = 1,
  String id = "c1",
}) => WorkCase(
  id: id,
  initialMailId: "m1",
  title: "[단가 인상 안내] 깐양파 10kg 11월 공급가 조정 및 납품 일정 변경 안내드립니다",
  sender: "very.long.sender.address.for.overflow@example.invalid",
  senderName: "주식회사 아주긴이름의거래처식자재유통 영업1팀 담당자",
  receivedAt: "2026-11-10T00:00:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: "",
  inputRevision: revision,
  attachmentCount: 3,
  replySummary: const ReplySummary(requested: 8, responded: 2),
);

Future<void> _pump(
  WidgetTester tester,
  WorkCase workCase, {
  double width = 320,
  double textScale = 1,
  bool disableAnimations = false,
  bool card = true,
  bool selected = false,
  WorkspacePalette palette = WorkspacePalette.houseGreen,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(extensions: [palette]),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: RequestRow(
            workCase,
            selected: selected,
            card: card,
            onTap: () {},
          ),
        ),
      ),
    ),
  ),
);

/// Whether the ring's blink is scheduling frames.
bool _blinking(WidgetTester tester) => tester.hasRunningAnimations;

StepRingPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(StepRing),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as StepRingPainter;

class _Visible extends AppVisible {
  @override
  bool build() => true;
}

/// One page mixing rows with a working ring, a resting ring and no ring.
class _Queue implements WorkQueueRepository {
  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
  }) async => WorkQueuePage(
    items: [
      _case("Running", "EXTRACTING", revision: 2, id: "c1"),
      _case("Running", "WAITING_REPLY", id: "c2"),
      _case("Running", "FAILED", id: "c3"),
    ],
    counts: const WorkQueueCounts(running: 3, total: 3),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// The ring's label: its text carries word joiners, so it is found by its
/// plain semantics label.
Finder ringLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.semanticsLabel == label,
);

void main() {
  testWidgets("the current slice blinks while the AI works", (tester) async {
    await _pump(tester, _case("Running", "SELECTING_CANDIDATES"));
    expect(find.byType(StepRing), findsOneWidget);
    expect(find.text("2/5"), findsOneWidget);
    expect(ringLabel("후보 찾는 중"), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp("5단계 중 2단계 작업 중")), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_blinking(tester), isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(_blinking(tester), isTrue);
  });

  testWidgets("the ring stops when the AI rests and resumes on the next step", (
    tester,
  ) async {
    await _pump(tester, _case("Running", "SELECTING_CANDIDATES"));
    expect(_blinking(tester), isTrue);

    await _pump(tester, _case("Running", "WAITING_REPLY"));
    expect(find.text("3/5"), findsOneWidget);
    expect(ringLabel("거래처 회신 대기"), findsOneWidget);
    expect(_blinking(tester), isFalse);
    // Nothing left to settle: the ring is still.
    await tester.pumpAndSettle();

    await _pump(tester, _case("Running", "EXTRACTING", revision: 2));
    expect(find.text("4/5"), findsOneWidget);
    expect(ringLabel("거래처 회신 확인 중"), findsOneWidget);
    expect(_blinking(tester), isTrue);
  });

  testWidgets("reduce motion keeps the working ring still", (tester) async {
    await _pump(
      tester,
      _case("Running", "GENERATING_PLANS"),
      disableAnimations: true,
    );
    expect(find.text("5/5"), findsOneWidget);
    expect(_blinking(tester), isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets("a working ring is accent, a resting one grey", (tester) async {
    // A light accent: arcs must take the darker accentText.
    const palette = WorkspacePalette.charcoalAmber;
    expect(palette.accent, isNot(palette.accentText));

    await _pump(
      tester,
      _case("Running", "SELECTING_CANDIDATES"),
      palette: palette,
    );
    var painter = _painter(tester);
    expect(painter.doneColor, palette.accentText);
    expect(painter.current, 2);
    expect(painter.done, 1);
    expect(painter.still, isFalse);

    await _pump(tester, _case("Running", "WAITING_REPLY"), palette: palette);
    painter = _painter(tester);
    expect(painter.doneColor, palette.muted);
    expect(painter.current, isNull);
    expect(painter.done, 3);
    expect(_blinking(tester), isFalse);

    // Drafted but not sent: the third slice is not filled.
    await _pump(tester, _case("Pending", "WAITING_APPROVAL"), palette: palette);
    painter = _painter(tester);
    expect(find.text("3/5"), findsOneWidget);
    expect(painter.doneColor, palette.muted);
    expect(painter.current, isNull);
    expect(painter.done, 2);
  });

  testWidgets("reduce motion marks the current slice by tone", (tester) async {
    await _pump(
      tester,
      _case("Running", "SELECTING_CANDIDATES"),
      disableAnimations: true,
    );
    final painter = _painter(tester);
    expect(painter.still, isTrue);
    expect(painter.current, 2);
    expect(painter.done, 1);
    expect(StepRingPainter.stillOpacity, inExclusiveRange(0.3, 1));
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets("ring labels are never cut short at text scale $scale", (
      tester,
    ) async {
      for (final (workCase, label) in [
        (_case("Running", "EXTRACTING", revision: 2), "거래처 회신 확인 중"),
        (_case("Running", "EXTRACTING"), "요청 정보 확인 중"),
        (_case("Pending", "SEND_UNKNOWN"), "발송 결과 확인 필요"),
        (_case("Running", "REVIEW_READY"), "검토 결과 준비 완료"),
        (_case("Running", "GENERATING_PLANS"), "검토안 생성 중"),
      ]) {
        await _pump(
          tester,
          workCase,
          textScale: scale,
          disableAnimations: true,
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: ringLabel(label),
            matching: find.byType(RichText),
          ),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
        expect(paragraph.size.width, lessThanOrEqualTo(StepRing.width));
      }
    });
  }

  testWidgets("rings fit the web sidebar list at its narrowest", (
    tester,
  ) async {
    // The sidebar is at least 330 wide, less the panel's 12 padding a side.
    const width = 306.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workQueueRepositoryProvider.overrideWithValue(_Queue()),
          workCaseChangesProvider.overrideWith((ref) => const Stream.empty()),
          appVisibleProvider.overrideWith(_Visible.new),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: QueueGroupList()),
            ),
          ),
        ),
      ),
    );
    // A working ring never settles; see StepRing.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(RequestRow), findsNWidgets(3));
    expect(find.byType(StepRing), findsNWidgets(2));
    for (final ring in find.byType(StepRing).evaluate()) {
      final ringRect = tester.getRect(find.byWidget(ring.widget));
      expect(ringRect.right, lessThanOrEqualTo(width - 12));
      final row = find.ancestor(
        of: find.byWidget(ring.widget),
        matching: find.byType(RequestRow),
      );
      final title = tester.getRect(
        find.descendant(of: row, matching: find.textContaining("깐양파")),
      );
      // Indented 8 by the list, 14 by the row.
      expect(title.left, 22);
      expect(title.right, lessThanOrEqualTo(ringRect.left - 12));
    }
    // Stops the view model's polling timers.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("waiting, finished and stopped cases have no ring", (
    tester,
  ) async {
    for (final workCase in [
      _case("Waiting", "PENDING_START"),
      _case("Confirm", "ACKNOWLEDGED"),
      _case("Complete", "REVIEW_READY"),
      _case("Running", "FAILED"),
      _case("Pending", "ON_HOLD"),
      _case("Running", "SOMETHING_NEW"),
    ]) {
      await _pump(tester, workCase);
      expect(find.byType(StepRing), findsNothing, reason: workCase.statusCode);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets("a row without a ring keeps its full-width layout", (
    tester,
  ) async {
    await _pump(tester, _case("Waiting", "PENDING_START"));
    final title = tester.getSize(find.textContaining("깐양파"));
    // 320 minus the row's 14 + 12 padding.
    expect(title.width, 294);
  });

  for (final (width, scale) in [
    (320.0, 1.0),
    (320.0, 1.3),
    (240.0, 1.0),
    (240.0, 1.3),
    (320.0, 2.0),
  ]) {
    testWidgets("nothing overflows at width $width, text scale $scale", (
      tester,
    ) async {
      for (final workCase in [
        _case("Running", "EXTRACTING", revision: 2),
        _case("Pending", "SEND_UNKNOWN"),
        _case("Running", "REVIEW_READY"),
      ]) {
        for (final card in [true, false]) {
          await _pump(
            tester,
            workCase,
            width: width,
            textScale: scale,
            card: card,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(StepRing), findsOneWidget);
          final row = tester.getRect(find.byType(RequestRow));
          final ring = tester.getRect(find.byType(StepRing));
          final title = tester.getRect(find.textContaining("깐양파"));
          expect(row.width, width);
          expect(ring.right, lessThanOrEqualTo(row.right - 12));
          expect(title.right, lessThanOrEqualTo(ring.left - 12));
          // The middle number stays inside the arcs.
          final ringBox = tester.getRect(find.byType(CustomPaint).last);
          final number = tester.getRect(find.textContaining("/5"));
          expect(ringBox.contains(number.topLeft), isTrue);
          expect(ringBox.contains(number.bottomRight), isTrue);
        }
      }
    });
  }

  testWidgets("a selected row keeps its tap and outline with a ring", (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        home: Scaffold(
          body: RequestRow(
            _case("Running", "EXTRACTING"),
            selected: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(StepRing));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(RequestRow)).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    BorderSide outline() =>
        (tester
                    .widget<Material>(
                      find.descendant(
                        of: find.byType(RequestRow),
                        matching: find.byType(Material),
                      ),
                    )
                    .shape!
                as RoundedRectangleBorder)
            .side;
    expect(outline().width, 1.5);
    expect(outline().color, WorkspacePalette.houseGreen.accentText);

    await _pump(tester, _case("Running", "EXTRACTING"));
    expect(
      tester.getSemantics(find.byType(RequestRow)).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    expect(outline(), BorderSide.none);
  });
}
