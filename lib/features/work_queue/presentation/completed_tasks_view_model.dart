import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/work_queue_repository_impl.dart";
import "../domain/work_case.dart";
import "work_queue_view_model.dart";

part "completed_tasks_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// 완료 묶음(`TaskGroup.complete`): 구매안을 확정해 보관된 업무.
class CompletedTasks {
  const CompletedTasks({
    required this.items,
    required this.total,
    this.nextCursor,
    this.loadingMore = false,
  });

  /// 최신 수신순.
  final List<WorkCase> items;

  /// 검색어에 맞는 보관 업무 전체 건수(서버 counts.total).
  final int total;
  final String? nextCursor;
  final bool loadingMore;
}

/// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
/// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
/// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.
@Riverpod(retry: _noRetry)
class CompletedTasksViewModel extends _$CompletedTasksViewModel {
  static const pageSize = WorkQueueViewModel.pageSize;

  /// 업무가 바뀌었다는 알림이 몰려 와도 한 번만 다시 읽습니다.
  static const reloadDelay = Duration(seconds: 2);

  Timer? _reload;

  @override
  Future<CompletedTasks> build(String query) async {
    ref.onDispose(() => _reload?.cancel());
    // 확정·보관도 업무 변경으로 옵니다. 어느 업무가 보관됐는지는 다시 읽어야
    // 알 수 있어 목록 전체를 다시 읽습니다.
    ref.listen(workCaseChangesProvider, (_, next) {
      if (next.value != null) _reloadSoon();
    });
    final page = await ref
        .watch(workQueueRepositoryProvider)
        .getCases(query: query, limit: pageSize, archived: true);
    return CompletedTasks(
      items: page.items,
      total: page.counts.total,
      nextCursor: page.nextCursor,
    );
  }

  void _reloadSoon() {
    _reload?.cancel();
    _reload = Timer(reloadDelay, () {
      if (ref.mounted) ref.invalidateSelf();
    });
  }

  void refresh() => ref.invalidateSelf();

  Future<void> loadMore() async {
    final current = state.hasValue && !state.isLoading
        ? state.requireValue
        : null;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;
    state = AsyncData(
      CompletedTasks(
        items: current.items,
        total: current.total,
        nextCursor: cursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(workQueueRepositoryProvider)
          .getCases(
            query: query,
            cursor: cursor,
            limit: pageSize,
            archived: true,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        CompletedTasks(
          items: List.unmodifiable([...current.items, ...page.items]),
          total: current.total,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      // 보이던 목록을 그대로 두고 다시 누를 수 있게 합니다.
      if (ref.mounted) state = AsyncData(current);
    }
  }
}
