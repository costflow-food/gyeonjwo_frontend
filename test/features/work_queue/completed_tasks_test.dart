import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_case_change_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/completed_tasks_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";

WorkCase _archived(String id) => WorkCase(
  id: id,
  initialMailId: "m-$id",
  title: "한라푸드",
  sender: "sales@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  status: WorkCaseStatus.complete,
  statusCode: "Complete",
  processingStep: "REVIEW_READY",
  stepMessage: "",
  inputRevision: 1,
  attachmentCount: 0,
  archived: true,
);

/// Two pages of archived cases; records what each request asked for.
class _Archive implements WorkQueueRepository {
  final requests = <(String, String?, bool)>[];

  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
    bool archived = false,
  }) async {
    requests.add((query, cursor, archived));
    return WorkQueuePage(
      items: [_archived(cursor == null ? "a" : "b")],
      counts: const WorkQueueCounts(total: 2),
      nextCursor: cursor == null ? "next" : null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test("완료 reads the archived cases and pages through them", () async {
    final archive = _Archive();
    final changes = StreamController<WorkCaseChange>.broadcast();
    final container = ProviderContainer(
      overrides: [
        workQueueRepositoryProvider.overrideWithValue(archive),
        workCaseChangesProvider.overrideWith((ref) => changes.stream),
      ],
    );
    addTearDown(() {
      container.dispose();
      changes.close();
    });
    final provider = completedTasksViewModelProvider("딸기");
    container.listen(provider, (_, _) {});

    final first = await container.read(provider.future);
    expect(first.total, 2);
    expect(first.items.map((each) => each.id), ["a"]);
    expect(taskGroupOf(first.items.single), TaskGroup.complete);

    await container.read(provider.notifier).loadMore();
    final all = container.read(provider).requireValue;
    expect(all.items.map((each) => each.id), ["a", "b"]);
    expect(all.nextCursor, isNull);
    expect(archive.requests, [("딸기", null, true), ("딸기", "next", true)]);
  });
}
