import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_intake/data/mail_intake_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/intake_mail.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/mail_intake_repository.dart";
import "package:gyeonjwo_frontend/features/mail_intake/presentation/mail_intake_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_case_change_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";

class _Visible extends AppVisible {
  @override
  bool build() => true;

  void set(bool visible) => state = visible;
}

IntakeMail _mail(int index) => IntakeMail(
  mailId: "m$index",
  subject: "제목 $index",
  sender: "s$index@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  bodyText: "",
  reason: IntakeReason.uncertain,
  reasonDetail: "",
  attachments: const [],
  candidates: const [],
  revision: 1,
);

/// 30 pending mails, 25 per page like API-23's default.
class _Intake implements MailIntakeRepository {
  @override
  Future<IntakePage> getPending({String? cursor}) async {
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = start + 25 > 30 ? 30 : start + 25;
    return IntakePage(
      items: [for (var i = start; i < end; i++) _mail(i + 1)],
      totalPending: 30,
      nextCursor: end < 30 ? "$end" : null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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

/// Ten pages per load ("c1".."c9", then "more"); "more" waits on [late].
class _Queue implements WorkQueueRepository {
  final late = <String, Completer<WorkQueuePage>>{};
  int listReads = 0;
  final caseReads = <String>[];

  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
  }) {
    if (cursor == "more") {
      return (late[query] = Completer<WorkQueuePage>()).future;
    }
    listReads++;
    final page = cursor == null ? 0 : int.parse(cursor.substring(1));
    return Future.value(
      WorkQueuePage(
        items: [_case("$query-$page")],
        counts: const WorkQueueCounts(),
        nextCursor: page == 9 ? "more" : "c${page + 1}",
      ),
    );
  }

  @override
  Future<WorkCase?> refreshCase(WorkCase listed) async {
    caseReads.add(listed.id);
    return _case(listed.id, status: "Running", step: "B");
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test("the 26th pending mail shows after 더 불러오기", () async {
    final container = ProviderContainer(
      overrides: [
        mailIntakeRepositoryProvider.overrideWithValue(_Intake()),
        appVisibleProvider.overrideWith(_Visible.new),
      ],
    );
    addTearDown(container.dispose);
    final provider = mailIntakeViewModelProvider;
    container.listen(provider, (_, _) {});
    final first = await container.read(provider.future);
    expect(first.items, hasLength(25));
    expect(first.nextCursor, isNotNull);

    await container.read(provider.notifier).loadMore();
    final page = container.read(provider).requireValue;
    expect(page.items, hasLength(30));
    expect(page.items[25].mailId, "m26");
    expect(page.nextCursor, isNull);
  });

  group("work queue", () {
    late _Queue queue;
    late StreamController<WorkCaseChange> changes;
    late ProviderContainer container;

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
      container.listen(workQueueViewModelProvider, (_, _) {});
    });
    tearDown(() {
      container.dispose();
      changes.close();
    });

    WorkQueueViewModel viewModel() =>
        container.read(workQueueViewModelProvider.notifier);
    List<String> ids() => [
      for (final workCase
          in container.read(workQueueViewModelProvider).requireValue.items)
        workCase.id,
    ];

    test("a late page for the previous search never comes back", () async {
      viewModel().setQuery("a");
      await container.read(workQueueViewModelProvider.future);
      final loading = viewModel().loadMore();

      viewModel().setQuery("b");
      await container.read(workQueueViewModelProvider.future);
      queue.late["a"]!.complete(
        WorkQueuePage(
          items: [_case("a-late")],
          counts: const WorkQueueCounts(),
        ),
      );
      await loading;

      expect(ids(), everyElement(startsWith("b-")));
      expect(
        container.read(workQueueViewModelProvider).requireValue.query,
        "b",
      );
    });

    test("a changed case is re-read alone", () async {
      await container.read(workQueueViewModelProvider.future);
      final reads = queue.listReads;

      changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "-3"));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(queue.listReads, reads);
      expect(queue.caseReads, ["-3"]);
      final state = container.read(workQueueViewModelProvider).requireValue;
      expect(
        state.items.firstWhere((workCase) => workCase.id == "-3").statusCode,
        "Running",
      );
    });

    test("a hidden tab reads changes only once it shows", () async {
      await container.read(workQueueViewModelProvider.future);
      final visible = container.read(appVisibleProvider.notifier) as _Visible;
      visible.set(false);

      changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "-1"));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(queue.caseReads, isEmpty);

      visible.set(true);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(queue.caseReads, ["-1"]);
    });

    test("a deleted case leaves without a read", () async {
      await container.read(workQueueViewModelProvider.future);
      final reads = queue.listReads;

      changes.add(const WorkCaseChange(1, WorkCaseChangeKind.deleted, "-2"));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(queue.listReads, reads);
      expect(queue.caseReads, isEmpty);
      expect(ids(), isNot(contains("-2")));
    });
  });
}
