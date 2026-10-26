import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/app/app_router.dart";
import "package:gyeonjwo_frontend/features/analysis_stop/data/analysis_stop_data_source.dart";
import "package:gyeonjwo_frontend/features/analysis_stop/presentation/analysis_stop_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";

const _holdRequestId = "REQ-2026-1018-003";

class CountingStopDataSource implements AnalysisStopDataSource {
  final calls = <String, int>{};
  bool fail = false;

  @override
  Future<Map<String, dynamic>> fetchStopReason(String requestId) {
    calls.update(requestId, (count) => count + 1, ifAbsent: () => 1);
    if (fail) return Future.error(StateError("중단 사유 조회 실패"));
    return const PreviewAnalysisStopDataSource(latency: Duration.zero)
        .fetchStopReason(requestId);
  }
}

void main() {
  Future<void> showQueue(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MyApp()),
    );
    appRouter.go("/");
    await tester.pumpAndSettle();
  }

  Future<void> openReason(WidgetTester tester) async {
    final button = find.widgetWithText(OutlinedButton, "사유 보기");
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  test("Repository maps the REVIEW_REQUIRED issues for SCR-006", () async {
    final container = ProviderContainer.test(
      overrides: [
        analysisStopDataSourceProvider.overrideWithValue(
          CountingStopDataSource(),
        ),
      ],
    );
    final stop = await container.read(
      analysisStopViewModelProvider(_holdRequestId).future,
    );
    expect(stop.requestId, _holdRequestId);
    expect(stop.stageLabel, "요청 규격 확인 단계");
    expect(stop.issues, hasLength(1));
    expect(stop.issues.single.label, "비교 가능한 품목 규격");
  });

  test("Unknown request IDs fail instead of borrowing another reason", () {
    final container = ProviderContainer.test(
      overrides: [
        analysisStopDataSourceProvider.overrideWithValue(
          CountingStopDataSource(),
        ),
      ],
    );
    expect(
      container.read(analysisStopViewModelProvider("REQ-UNKNOWN").future),
      throwsStateError,
    );
  });

  testWidgets("사유 보기 opens SCR-006 and the close icon returns to the queue", (
    tester,
  ) async {
    await showQueue(tester);
    await openReason(tester);
    expect(find.text("분석을 중단했습니다"), findsOneWidget);
    expect(find.text("검토 필요 · 요청 규격 확인 단계"), findsOneWidget);
    expect(find.text("비교 가능한 품목 규격"), findsOneWidget);
    expect(find.text("냉동·무가당 여부와 포장 규격을 확인할 수 없습니다."), findsOneWidget);
    // 값 직접 수정·부분 계산·메일 발송 동작은 두지 않습니다(09 SCR-006).
    expect(find.text("메일 발송"), findsNothing);
    // 업무 큐로 버튼은 X 닫기와 같아 두지 않습니다.
    expect(find.text("업무 큐로"), findsNothing);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    expect(find.text("분석을 중단했습니다"), findsNothing);
    expect(find.text("흩어진 요청을, 한눈에 검토하세요."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("원문 확인 opens SCR-004 for the same stopped request", (
    tester,
  ) async {
    await showQueue(tester);
    await openReason(tester);
    final sourceButton = find.widgetWithText(OutlinedButton, "원문 확인");
    expect(tester.widget<OutlinedButton>(sourceButton).onPressed, isNotNull);
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();
    expect(find.text("분석을 중단했습니다"), findsNothing);
    expect(find.text("원문·근거 보기"), findsOneWidget);
    // This request has no source fixture; never substitute another request.
    expect(find.text("이 요청의 합성 원문이 준비되지 않았습니다."), findsOneWidget);
    expect(find.text("A사 영업담당 (합성)"), findsNothing);
    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text("흩어진 요청을, 한눈에 검토하세요."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("SCR-006 shows an error and reloads on retry", (tester) async {
    final source = CountingStopDataSource()..fail = true;
    await showQueue(
      tester,
      overrides: [analysisStopDataSourceProvider.overrideWithValue(source)],
    );
    await openReason(tester);
    expect(find.text("다시 시도"), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(source.calls[_holdRequestId], 1);
    source.fail = false;
    await tester.tap(find.text("다시 시도"));
    await tester.pumpAndSettle();
    expect(find.text("비교 가능한 품목 규격"), findsOneWidget);
    expect(source.calls[_holdRequestId], 2);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(1440, 900), const Size(320, 640)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets("SCR-006 fits $size at text scale $scale", (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await showQueue(tester, size: size);
        await openReason(tester);
        expect(find.text("분석을 중단했습니다"), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
