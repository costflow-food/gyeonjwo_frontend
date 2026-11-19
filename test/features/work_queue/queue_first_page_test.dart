import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_case_change_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_state.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/task_list.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

class _Visible extends AppVisible {
  @override
  bool build() => true;
}

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(status: AuthSessionStatus.signedIn);
}

WorkCase _case(String id, {String status = "Waiting", String step = "A"}) =>
    WorkCase(
      id: id,
      initialMailId: "mail-$id",
      title: "제목 $id",
      sender: "$id@example.invalid",
      receivedAt: "2026-11-10T00:00:00Z",
      status: WorkCaseStatus.fromCode(status),
      statusCode: status,
      processingStep: step,
      stepMessage: step,
      inputRevision: 1,
      attachmentCount: 0,
    );

/// The server counts by its old tabs, so only its total is used.
const _serverCounts = WorkQueueCounts(total: 6);

/// Three pages of two cases per search: "q-0-0", "q-0-1", "q-1-0", ...
/// The last case waits for supplier replies (진행 중), the others are the
/// user's turn (확인 필요). A request listed in [gates] waits for its
/// completer; one listed in [failing] fails once.
class _Queue implements WorkQueueRepository {
  final gates = <String, Completer<void>>{};
  final failing = <String>{};
  final requests = <String>[];
  final caseReads = <String>[];

  /// Makes "[query]|[cursor]" wait; complete or fail the result to let go.
  Completer<void> hold(String query, String? cursor) =>
      gates["$query|$cursor"] = Completer<void>();

  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
    bool archived = false,
  }) async {
    // 보관(완료) 목록은 비어 있습니다.
    if (archived) {
      return const WorkQueuePage(items: [], counts: WorkQueueCounts());
    }
    final key = "$query|$cursor";
    requests.add(key);
    if (failing.remove(key)) throw StateError("timeout");
    await gates.remove(key)?.future;
    final page = cursor == null ? 0 : int.parse(cursor);
    return WorkQueuePage(
      items: [
        _case("$query-$page-0"),
        page == 2
            ? _case("$query-$page-1", status: "Running", step: "WAITING_REPLY")
            : _case("$query-$page-1"),
      ],
      counts: _serverCounts,
      nextCursor: page == 2 ? null : "${page + 1}",
    );
  }

  @override
  Future<WorkCase?> refreshCase(WorkCase listed) async {
    caseReads.add(listed.id);
    return listed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Queue queue;
  late StreamController<WorkCaseChange> changes;
  late ProviderContainer container;
  late List<WorkQueueState> shown;

  setUp(() {
    queue = _Queue();
    changes = StreamController<WorkCaseChange>.broadcast();
    container = ProviderContainer(
      overrides: [
        workQueueRepositoryProvider.overrideWithValue(queue),
        workCaseChangesProvider.overrideWith((ref) => changes.stream),
        appVisibleProvider.overrideWith(_Visible.new),
      ],
    );
    shown = [];
    container.listen(workQueueViewModelProvider, (_, next) {
      if (next.hasValue) shown.add(next.requireValue);
    });
  });
  tearDown(() {
    container.dispose();
    changes.close();
  });

  WorkQueueViewModel viewModel() =>
      container.read(workQueueViewModelProvider.notifier);
  WorkQueueState state() =>
      container.read(workQueueViewModelProvider).requireValue;
  List<String> ids() => [for (final workCase in state().items) workCase.id];
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test("the first page shows before the other pages arrive", () async {
    final second = queue.hold("", "1");

    await container.read(workQueueViewModelProvider.future);
    await settle();

    expect(ids(), ["-0-0", "-0-1"]);
    expect(state().loadingMore, isTrue);
    expect(state().nextCursor, isNotNull);
    // Not every case is in hand yet: the server's total, and the groups
    // of the cases in hand (the server does not count by group).
    expect(state().counts.total, 6);
    expect(state().counts.confirm, 2);
    expect(state().counts.running, 0);
    expect(state().allCounts!.confirm, 2);
    // A tab and a selection made meanwhile survive the rest landing.
    viewModel().setStatus(TaskGroup.running);
    viewModel().select("-2-1");

    second.complete();
    await settle();

    expect(ids(), ["-0-0", "-0-1", "-1-0", "-1-1", "-2-0", "-2-1"]);
    expect(state().loadingMore, isFalse);
    expect(state().nextCursor, isNull);
    // Every case is in hand: counted here, by group.
    expect(state().counts.confirm, 5);
    expect(state().counts.running, 1);
    expect(state().counts.total, 6);
    expect(state().allCounts!.confirm, 5);
    expect(state().status, TaskGroup.running);
    expect(state().selectedId, "-2-1");
    expect(queue.requests, ["|null", "|1", "|2"]);
    // The rest is added in one step, so rows move at most once.
    expect({for (final each in shown) each.items.length}, {2, 6});
  });

  test("a search change drops the pages of the previous search", () async {
    final late = queue.hold("a", "1");
    viewModel().setQuery("a");
    await container.read(workQueueViewModelProvider.future);
    await settle();
    expect(ids(), ["a-0-0", "a-0-1"]);

    viewModel().setQuery("b");
    await container.read(workQueueViewModelProvider.future);
    await settle();
    late.complete();
    await settle();

    expect(ids(), hasLength(6));
    expect(ids(), everyElement(startsWith("b-")));
    expect(state().query, "b");
    expect(state().loadingMore, isFalse);
    // The previous search stops reading once it is replaced.
    expect(queue.requests, isNot(contains("a|2")));
  });

  test("a failed page keeps what arrived; 더 불러오기 continues", () async {
    final third = queue.hold("", "2");
    await container.read(workQueueViewModelProvider.future);
    await settle();

    third.completeError(StateError("timeout"));
    await settle();

    expect(container.read(workQueueViewModelProvider).hasError, isFalse);
    expect(ids(), ["-0-0", "-0-1", "-1-0", "-1-1"]);
    expect(state().loadingMore, isFalse);
    expect(state().nextCursor, "2");
    expect(state().counts.total, 6);
    expect(state().counts.confirm, 4);

    await viewModel().loadMore();

    expect(ids(), hasLength(6));
    expect(state().nextCursor, isNull);
    expect(state().counts.running, 1);
  });

  test("a reload of the shown search swaps the whole list at once", () async {
    await container.read(workQueueViewModelProvider.future);
    await settle();
    expect(ids(), hasLength(6));
    shown.clear();

    viewModel().refresh();
    await container.read(workQueueViewModelProvider.future);
    await settle();

    expect(shown, isNotEmpty);
    expect([for (final each in shown) each.items.length], everyElement(6));
    expect(shown.any((each) => each.loadingMore), isFalse);
  });

  test("a change during the load is read once the rest is in", () async {
    final second = queue.hold("", "1");
    await container.read(workQueueViewModelProvider.future);
    await settle();

    changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "-0-1"));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(queue.caseReads, isEmpty);

    second.complete();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(queue.caseReads, ["-0-1"]);
    expect(ids(), hasLength(6));
  });

  test("a selection no page holds is dropped once the rest is in", () async {
    final second = queue.hold("", "1");
    await container.read(workQueueViewModelProvider.future);
    await settle();
    viewModel().select("gone");
    expect(state().selectedId, "gone");

    second.complete();
    await settle();

    expect(ids(), hasLength(6));
    expect(state().selectedId, isNull);
  });

  test("a reload failing during the load ends the wait for the rest", () async {
    final second = queue.hold("", "1");
    await container.read(workQueueViewModelProvider.future);
    await settle();
    expect(state().loadingMore, isTrue);

    queue.failing.add("|null");
    viewModel().refresh();
    await settle();
    await settle();
    // The pages of the replaced load are dropped.
    second.complete();
    await settle();

    final failed = container.read(workQueueViewModelProvider);
    expect(failed.hasError, isTrue);
    expect(failed.isLoading, isFalse);
    expect(ids(), ["-0-0", "-0-1"]);
    expect(state().loadingMore, isFalse);
    expect(state().nextCursor, "1");
    expect(viewModel().loadingRest, isFalse);

    // "더 불러오기" and changed-case reads work again.
    await viewModel().loadMore();
    expect(ids(), ["-0-0", "-0-1", "-1-0", "-1-1"]);
    changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "-0-1"));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(queue.caseReads, ["-0-1"]);
  });

  test("더 불러오기 after a failed search reads that search again", () async {
    queue.hold("", "1");
    await container.read(workQueueViewModelProvider.future);
    await settle();

    queue.failing.add("b|null");
    viewModel().setQuery("b");
    await settle();
    await settle();
    expect(container.read(workQueueViewModelProvider).hasError, isTrue);
    expect(state().query, "");
    expect(state().loadingMore, isFalse);

    // The cursor on screen belongs to the previous search.
    await viewModel().loadMore();
    await container.read(workQueueViewModelProvider.future);
    await settle();

    expect(queue.requests.where((key) => key == "b|null"), hasLength(2));
    // Never the previous search's cursor with the new search.
    expect(
      queue.requests.indexOf("b|1"),
      greaterThan(queue.requests.lastIndexOf("b|null")),
    );
    expect(ids(), hasLength(6));
    expect(ids(), everyElement(startsWith("b-")));
  });

  group("polling", () {
    // Replaces the signed-out container of setUp, which never polls.
    ProviderContainer signedIn() {
      container.dispose();
      queue.requests.clear();
      container = ProviderContainer(
        overrides: [
          workQueueRepositoryProvider.overrideWithValue(queue),
          workCaseChangesProvider.overrideWith((ref) => changes.stream),
          appVisibleProvider.overrideWith(_Visible.new),
          authSessionViewModelProvider.overrideWith(_SignedIn.new),
        ],
      );
      container.listen(workQueueViewModelProvider, (_, _) {});
      return container;
    }

    testWidgets("waits for the rest, then runs once a minute", (tester) async {
      final second = queue.hold("", "1");
      final container = signedIn();
      await tester.pump(const Duration(milliseconds: 1));
      expect(queue.requests, ["|null", "|1"]);

      await tester.pump(const Duration(seconds: 61));
      expect(queue.requests, ["|null", "|1"]);

      second.complete();
      await tester.pump(const Duration(milliseconds: 1));
      expect(queue.requests, ["|null", "|1", "|2"]);

      await tester.pump(const Duration(seconds: 59));
      expect(queue.requests, hasLength(3));
      await tester.pump(const Duration(seconds: 2));
      expect(queue.requests.sublist(3), ["|null", "|1", "|2"]);
      container.dispose();
    });

    testWidgets("a failed first load is read again after 15 seconds", (
      tester,
    ) async {
      queue.failing.add("|null");
      final second = queue.hold("", "1");
      final container = signedIn();
      await tester.pump(const Duration(milliseconds: 1));
      expect(container.read(workQueueViewModelProvider).hasError, isTrue);
      expect(queue.requests, ["|null"]);

      await tester.pump(const Duration(seconds: 14));
      expect(queue.requests, ["|null"]);

      // One request brings the first page back; the rest follows.
      await tester.pump(const Duration(seconds: 2));
      final value = container.read(workQueueViewModelProvider);
      expect(value.hasError, isFalse);
      expect(value.requireValue.items, hasLength(2));
      expect(queue.requests, ["|null", "|null", "|1"]);

      second.complete();
      await tester.pump(const Duration(milliseconds: 1));
      expect(value.requireValue.items, hasLength(2));
      expect(
        container.read(workQueueViewModelProvider).requireValue.items,
        hasLength(6),
      );
      container.dispose();
    });

    testWidgets("runs again once 더 불러오기 finished a failed load", (
      tester,
    ) async {
      queue.failing.add("|2");
      final container = signedIn();
      await tester.pump(const Duration(milliseconds: 1));
      final notifier = container.read(workQueueViewModelProvider.notifier);
      expect(queue.requests, ["|null", "|1", "|2"]);

      unawaited(notifier.loadMore());
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        container.read(workQueueViewModelProvider).requireValue.nextCursor,
        isNull,
      );
      expect(queue.requests, hasLength(4));

      await tester.pump(const Duration(seconds: 61));
      expect(queue.requests.sublist(4), ["|null", "|1", "|2"]);
      container.dispose();
    });
  });

  testWidgets("a tab with no case yet offers 더 불러오기, not an empty note", (
    tester,
  ) async {
    final second = queue.hold("", "1");
    TaskGroup? tab;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workQueueRepositoryProvider.overrideWithValue(queue),
          // 묶음은 접힌 채로 시작하므로 '품목 미확인' 묶음을 펼쳐 두고 봅니다.
          taskListMemoryProvider.overrideWithValue(
            TaskListMemory()..expanded.add(null),
          ),
          workCaseChangesProvider.overrideWith((ref) => changes.stream),
          appVisibleProvider.overrideWith(_Visible.new),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [WorkspacePalette.lds]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TaskList(
                status: tab,
                selectedId: null,
                onOpen: (_) {},
                onTab: (next) => setState(() => tab = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    // 진행 중 has no case on the first page; its case is on the last one.
    await tester.tap(find.textContaining("진행 중"));
    await tester.pump();

    expect(find.text("조건에 맞는 업무가 없습니다."), findsNothing);
    expect(find.text("더 불러오기"), findsOneWidget);

    second.complete();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text("제목 -2-1"), findsOneWidget);
    expect(find.text("더 불러오기"), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
