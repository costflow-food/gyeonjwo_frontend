import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/candidate.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/candidate_selection.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// The "still looking for candidates" line on a 360-wide phone: a layout
/// overflow fails the test.

class _NotReady implements WorkQueueRepository {
  @override
  Future<CandidateSet> getCandidates(String caseId) async =>
      throw const WorkQueueFailure("CANDIDATES_NOT_READY", "후보를 찾는 중입니다.");

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

WorkCase _case() => WorkCase(
  id: "c1",
  initialMailId: "m1",
  title: "[단가 인상 안내] 깐양파 10kg 11월 공급가 조정",
  sender: "kim@example.invalid",
  receivedAt: "2026-11-11T00:12:00Z",
  status: WorkCaseStatus.fromCode("Running"),
  statusCode: "Running",
  processingStep: "SELECTING_CANDIDATES",
  stepMessage: "",
  inputRevision: 1,
  attachmentCount: 0,
  itemName: "깐양파",
  allowedActions: const [WorkCaseAction.selectCandidates],
);

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets("candidate search notice wraps on a phone at text scale $scale", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workQueueRepositoryProvider.overrideWithValue(_NotReady()),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: CandidateSelection(workCase: _case(), page: true),
          ),
        ),
      );
      // The spinner never settles, so pump a fixed time instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final notice = find.text("에이전트가 견적 요청 후보를 찾고 있습니다.");
      expect(notice, findsOneWidget);
      final rect = tester.getRect(notice);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360 - 16));
      expect(tester.takeException(), isNull);

      // Drop the page so its 3-second retry timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
