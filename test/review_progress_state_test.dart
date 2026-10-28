import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";
import "package:gyeonjwo_frontend/features/purchase_review/presentation/purchase_review_view_model.dart";
import "package:gyeonjwo_frontend/features/review_progress/domain/review_phase.dart";
import "package:gyeonjwo_frontend/features/review_progress/presentation/review_progress_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_data_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/request_item.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_state.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";

import "support/controlled_review_data_source.dart";

const _first = "REQ-2026-1019-003";
const _second = "REQ-2026-1019-002";

void main() {
  test(
    "Domain composes progress before filtering and leaves raw data intact",
    () {
      const request = RequestItem(
        id: _first,
        title: "냉동 딸기",
        supplier: "A사",
        attachments: 1,
        status: "검토 대기",
        date: "2026.10.19",
        time: "10:24",
        action: "실행",
      );
      for (final (phase, status, action) in [
        (ReviewPhase.idle, "검토 대기", "실행"),
        (ReviewPhase.running, "검토 중", "진행 보기"),
        (ReviewPhase.completed, "완료", "결과 보기"),
        (ReviewPhase.failed, "검토 필요", "다시 시도"),
      ]) {
        final state = WorkQueueState.fromRequests(
          requests: [request],
          progress: {_first: phase},
          selectedStatus: status,
          query: " a사 ",
        );
        expect(state.visibleRequests.single.status, status);
        expect(state.visibleRequests.single.action, action);
        expect(state.countFor(status), 1);
        expect(request.status, "검토 대기");
      }
    },
  );

  test(
    "Opening the queue does not start reviews; its state tracks async results",
    () async {
      final source = ControlledReviewDataSource();
      final container = ProviderContainer.test(
        overrides: [
          purchaseReviewDataSourceProvider.overrideWithValue(source),
          workQueueDataSourceProvider.overrideWithValue(
            const PreviewWorkQueueDataSource(latency: Duration.zero),
          ),
        ],
      );
      final subscription = container.listen(
        workQueueViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(workQueueViewModelProvider.future);
      expect(source.calls, isEmpty);
      final queue = container.read(workQueueViewModelProvider.notifier);
      queue.selectStatus("검토 대기");
      queue.search("A사");
      final progress = reviewProgressViewModelProvider(_first);
      final operation = container.read(progress.notifier).start();
      await container.pump();
      var state = await container.read(workQueueViewModelProvider.future);
      expect(state.requests.first.status, "검토 중");
      expect(state.visibleRequests, isEmpty);
      expect(state.selectedStatus, "검토 대기");
      expect(state.query, "A사");
      source.succeed(_first);
      await operation;
      await container.pump();
      state = await container.read(workQueueViewModelProvider.future);
      expect(state.requests.first.status, "완료");
      expect(state.requests.first.action, "결과 보기");
      expect(container.read(progress).requireValue, ReviewPhase.completed);
      queue.refresh();
      state = await container.read(workQueueViewModelProvider.future);
      expect(state.requests.first.status, "완료");
      expect(state.query, "A사");
      expect(source.calls[_first], 1);
    },
  );

  test(
    "Requests stay independent and reuse results after the listener closes",
    () async {
      final source = ControlledReviewDataSource();
      final container = ProviderContainer.test(
        overrides: [purchaseReviewDataSourceProvider.overrideWithValue(source)],
      );
      final first = reviewProgressViewModelProvider(_first);
      final second = reviewProgressViewModelProvider(_second);
      final listener = container.listen(first, (_, _) {});
      final operation = container.read(first.notifier).start();
      listener.close();
      await container.pump();
      expect(container.read(first).isLoading, isTrue);
      expect(container.read(second).requireValue, ReviewPhase.idle);
      final duplicate = container.read(first.notifier).start();
      await duplicate;
      expect(source.calls[_first], 1);
      source.succeed(_first);
      await operation;
      final cached = container
          .read(purchaseReviewViewModelProvider(_first))
          .requireValue;
      await container.read(first.notifier).start();
      expect(container.read(first).requireValue, ReviewPhase.completed);
      expect(
        container.read(purchaseReviewViewModelProvider(_first)).requireValue,
        same(cached),
      );
      expect(source.calls[_first], 1);
    },
  );

  test(
    "A failed result remains an error until a manual retry succeeds",
    () async {
      final source = ControlledReviewDataSource();
      final container = ProviderContainer.test(
        overrides: [purchaseReviewDataSourceProvider.overrideWithValue(source)],
      );
      final provider = reviewProgressViewModelProvider(_first);
      final notifier = container.read(provider.notifier);
      final first = notifier.start();
      source.fail(_first);
      await first;
      expect(container.read(provider).hasError, isTrue);
      final retry = notifier.start();
      expect(container.read(provider).isLoading, isTrue);
      expect(source.calls[_first], 2);
      source.succeed(_first);
      await retry;
      expect(container.read(provider).requireValue, ReviewPhase.completed);
    },
  );
}
