import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/review_progress/data/review_progress_repository_impl.dart";
import "package:gyeonjwo_frontend/features/review_progress/domain/review_progress_repository.dart";
import "package:gyeonjwo_frontend/features/review_progress/presentation/review_progress_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_case_change_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";

class _Progress implements ReviewProgressRepository {
  final calls = <String>[];

  /// The next read waits for this.
  Completer<void>? gate;

  // WAITING_REPLY is not a running step, so the 3 s poll stays off and
  // every extra call here comes from a change signal.
  @override
  Future<CaseProgress> getProgress(String caseId) async {
    calls.add(caseId);
    final waiting = gate;
    gate = null;
    await waiting?.future;
    return CaseProgress(
      caseId: caseId,
      status: "IN_PROGRESS",
      processingStep: "WAITING_REPLY",
      inputRevision: 1,
    );
  }
}

/// Longer than the 300 ms the view model waits after a signal.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 400));

void main() {
  late _Progress repository;
  late StreamController<WorkCaseChange> changes;
  late ProviderContainer container;

  setUp(() async {
    repository = _Progress();
    changes = StreamController<WorkCaseChange>.broadcast();
    container = ProviderContainer(
      overrides: [
        reviewProgressRepositoryProvider.overrideWithValue(repository),
        workCaseChangesProvider.overrideWith((ref) => changes.stream),
      ],
    );
    final provider = reviewProgressViewModelProvider("case-1");
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    expect(repository.calls, ["case-1"]);
  });
  tearDown(() {
    container.dispose();
    changes.close();
  });

  test("a change of another case does not re-read this case", () async {
    changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "case-2"));
    changes.add(const WorkCaseChange(2, WorkCaseChangeKind.inserted, "case-3"));
    changes.add(const WorkCaseChange(3, WorkCaseChangeKind.deleted, "case-4"));
    await _settle();
    expect(repository.calls, ["case-1"]);
  });

  test("a change of this case re-reads it once", () async {
    changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "case-1"));
    await _settle();
    expect(repository.calls, ["case-1", "case-1"]);
  });

  test("a resync after a reconnect re-reads this case", () async {
    changes.add(const WorkCaseChange(1, WorkCaseChangeKind.resync));
    await _settle();
    expect(repository.calls, ["case-1", "case-1"]);
  });

  test("a change during a read is read again after it", () async {
    final slow = repository.gate = Completer<void>();
    changes.add(const WorkCaseChange(1, WorkCaseChangeKind.updated, "case-1"));
    await _settle();
    expect(repository.calls, hasLength(2));

    // The running read may have seen the case before this change.
    changes.add(const WorkCaseChange(2, WorkCaseChangeKind.updated, "case-1"));
    await _settle();
    expect(repository.calls, hasLength(2));

    slow.complete();
    await _settle();
    expect(repository.calls, hasLength(3));
  });
}
