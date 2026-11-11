import "dart:async";
import "dart:typed_data";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/app_visibility.dart";
import "../../auth/presentation/auth_session_view_model.dart";
import "../../mail_draft/data/mail_draft_repository_impl.dart";
import "../../review_progress/data/review_progress_repository_impl.dart";
import "../data/work_case_change_source.dart";
import "../data/work_queue_repository_impl.dart";
import "../domain/candidate.dart";
import "../domain/work_case.dart";
import "../domain/work_queue_repository.dart";
import "../domain/work_queue_state.dart";

part "work_queue_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
class WorkQueueViewModel extends _$WorkQueueViewModel {
  /// Fallback when Realtime is down or misses a change (08 §11: 15 seconds).
  /// Any reload restarts it, so it only fires after a quiet interval. It
  /// waits while the browser tab is hidden.
  static const pollInterval = Duration(seconds: 15);

  /// Changed cases re-read one by one (API-02) per burst; past this the
  /// whole queue is cheaper to re-read.
  static const maxCaseReads = 5;

  String? _selectedId;
  Timer? _refreshTimer;
  Timer? _poll;

  /// API-01 page size (server maximum) and how many pages one load reads.
  /// Up to 1,000 cases arrive in one load, so the status tabs can filter
  /// in memory; past that, "더 불러오기" reads the rest.
  static const pageSize = 100;
  static const maxPages = 10;

  /// More pages were loaded; a poll would drop them, so it waits.
  bool _extended = false;

  /// 상태 탭(null은 전체)은 받아 둔 목록을 화면에서 거릅니다. 검색어는
  /// 메일 제목까지 보는 서버(API-01 q)가 거릅니다.
  WorkCaseStatus? _status;
  String _query = "";

  /// counts.waiting from the last response without a search (status does
  /// not change counts), for the home summary.
  int? _allWaiting;

  /// Bumped by every read that replaces or extends the list (load, poll,
  /// load more, changed cases). A response is applied only while its
  /// generation is still the newest, so a late response, such as one for
  /// the previous search, never overwrites a newer list.
  int _generation = 0;

  /// Realtime changes not applied yet: case id to "deleted". [_reloadAll]
  /// asks for a whole re-read instead (reconnect, a new case).
  final _changed = <String, bool>{};
  bool _reloadAll = false;
  bool _readingChanges = false;

  /// A poll came due while the tab was hidden; it runs when the tab shows.
  bool _pollWaiting = false;

  @override
  Future<WorkQueueState> build() async {
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _poll?.cancel();
    });
    _extended = false;
    // This load covers every change signalled so far.
    _changed.clear();
    _reloadAll = false;
    _generation++;
    // Supabase says a case changed (new mail, AI step, deletion): re-read
    // only that case so only the widgets showing it update.
    ref.listen(workCaseChangesProvider, (_, next) {
      final change = next.value;
      if (change != null) _onChange(change);
    });
    ref.listen(appVisibleProvider, (_, visible) {
      if (visible) _catchUp();
    });
    try {
      return _fromPage(await _fetchAll(ref.watch(workQueueRepositoryProvider)));
    } finally {
      // Also after a failed first load, so the queue recovers by itself.
      _schedulePoll();
      // Changes that arrived while this load was running.
      if ((_changed.isNotEmpty || _reloadAll) && ref.read(appVisibleProvider)) {
        _readChangesSoon();
      }
    }
  }

  /// Every case for the search, all tabs, page after page up to [maxPages].
  /// Counts come from the first page; the server counts the whole search.
  Future<WorkQueuePage> _fetchAll(WorkQueueRepository repository) async {
    final first = await repository.getCases(query: _query, limit: pageSize);
    final items = [...first.items];
    var cursor = first.nextCursor;
    for (var pages = 1; cursor != null && pages < maxPages; pages++) {
      final page = await repository.getCases(
        query: _query,
        cursor: cursor,
        limit: pageSize,
      );
      items.addAll(page.items);
      cursor = page.nextCursor;
    }
    return WorkQueuePage(
      items: List.unmodifiable(items),
      counts: first.counts,
      nextCursor: cursor,
    );
  }

  /// Tab counts from the cases in hand, so held and failed cases (Pending)
  /// count under 진행 중 like the tab shows them. With cases still on the
  /// server, the server's counts are the only complete ones.
  static WorkQueueCounts _counts(
    List<WorkCase> items,
    String? nextCursor,
    WorkQueueCounts server,
  ) => nextCursor == null ? WorkQueueCounts.fromCases(items) : server;

  WorkQueueState _fromPage(WorkQueuePage page) {
    // A case accepted elsewhere disappears; drop a selection that no longer exists.
    if (!page.items.any((workCase) => workCase.id == _selectedId)) {
      _selectedId = null;
    }
    final counts = _counts(page.items, page.nextCursor, page.counts);
    if (_query.isEmpty) _allWaiting = counts.waiting;
    return WorkQueueState(
      items: page.items,
      counts: counts,
      nextCursor: page.nextCursor,
      status: _status,
      query: _query,
      selectedId: _selectedId,
      allWaiting: _allWaiting,
    );
  }

  void refresh() => ref.invalidateSelf();

  /// 상태 탭을 바꿉니다. null은 전체입니다. 받아 둔 목록을 거를 뿐이라
  /// 서버를 다시 부르지 않습니다.
  void setStatus(WorkCaseStatus? status) {
    if (status == _status) return;
    _status = status;
    final current = state.value;
    // While a load is still in flight it reads [_status] when it lands.
    if (current != null) state = AsyncData(current.withStatus(status));
  }

  /// 제목·보낸 사람 검색. 화면에서 입력을 잠시 모은 뒤 부릅니다.
  void setQuery(String query) {
    final trimmed = query.trim();
    if (trimmed == _query) return;
    _query = trimmed;
    ref.invalidateSelf();
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(pollInterval, _pollNow);
  }

  /// Replaces the list without a loading state, so the queue does not
  /// flash. Uses the open search and keeps the open tab. Skipped while
  /// signed out or after load more, and waits while the tab is hidden; a
  /// failure keeps what is shown and the next poll tries again. After a
  /// failed load it keeps trying until the list shows.
  Future<void> _pollNow() async {
    if (!ref.read(appVisibleProvider)) {
      _pollWaiting = true;
      return;
    }
    final signedIn =
        ref.read(authSessionViewModelProvider).asData?.value.isSignedIn ??
        false;
    final current = state.hasValue && !state.isLoading
        ? state.requireValue
        : null;
    final failed = state.hasError && !state.isLoading;
    if (signedIn &&
        (failed || (current != null && !_extended && !current.loadingMore))) {
      final generation = ++_generation;
      // A whole re-read covers every change signalled so far.
      final covered = Map.of(_changed);
      final reloadAll = _reloadAll;
      _changed.clear();
      _reloadAll = false;
      var applied = false;
      var dropped = false;
      try {
        final page = await _fetchAll(ref.read(workQueueRepositoryProvider));
        if (!ref.mounted) return;
        applied = generation == _generation;
        dropped = !applied;
        if (applied) state = AsyncData(_fromPage(page));
      } catch (_) {
        if (!ref.mounted) return;
      }
      if (!applied) {
        // Not shown: those changes still need a read. After a failure the
        // next poll covers them.
        for (final entry in covered.entries) {
          _changed.putIfAbsent(entry.key, () => entry.value);
        }
        _reloadAll = _reloadAll || reloadAll;
        if (dropped && (_changed.isNotEmpty || _reloadAll)) _readChangesSoon();
      }
    }
    if (ref.mounted) _schedulePoll();
  }

  /// The tab shows again: run the poll that came due, or the changes that
  /// arrived while it was hidden.
  void _catchUp() {
    if (_pollWaiting) {
      _pollWaiting = false;
      // Takes the pending changes along unless it is skipped.
      _pollNow();
    }
    if (_reloadAll || _changed.isNotEmpty) _readChangesSoon();
  }

  void _onChange(WorkCaseChange change) {
    final caseId = change.caseId;
    if (caseId == null || change.kind == WorkCaseChangeKind.inserted) {
      // A new case needs its title, sender and place in the search: API-01.
      _reloadAll = true;
    } else {
      _changed[caseId] = change.kind == WorkCaseChangeKind.deleted;
    }
    // A hidden tab reads nothing; [_catchUp] runs these when it shows.
    if (ref.read(appVisibleProvider)) _readChangesSoon();
  }

  /// One read for a burst of changes (e.g. one mail touching several rows).
  void _readChangesSoon() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (ref.mounted) _readChanges();
    });
  }

  /// Re-reads only the changed cases (API-02) and swaps them into the list;
  /// a deleted case leaves it. Falls back to re-reading the whole queue for
  /// a new case, a reconnect, many changes, a linked reply (its reply
  /// summary is only in API-01), or a failed read.
  Future<void> _readChanges() async {
    // A running read, load or load more schedules these when it ends.
    if (_readingChanges || state.isLoading) return;
    final current = state.hasValue ? state.requireValue : null;
    if (current?.loadingMore ?? false) return;
    if (_reloadAll || current == null || _changed.length > maxCaseReads) {
      ref.invalidateSelf();
      return;
    }
    final changed = Map.of(_changed);
    _changed.clear();
    final listed = {
      for (final workCase in current.items) workCase.id: workCase,
    };
    final wholeList = current.nextCursor == null && _query.isEmpty;
    final reads = <WorkCase>[];
    final deleted = <String>{};
    for (final MapEntry(key: id, value: gone) in changed.entries) {
      final workCase = listed[id];
      if (workCase == null) {
        // Missing from a list that holds every case: it may have come back
        // (restored), which only API-01 can place. Otherwise it is outside
        // this search or past the loaded pages.
        if (!gone && wholeList) {
          ref.invalidateSelf();
          return;
        }
      } else if (gone) {
        deleted.add(id);
      } else {
        reads.add(workCase);
      }
    }
    if (reads.isEmpty && deleted.isEmpty) return;
    final generation = ++_generation;
    _readingChanges = true;
    List<WorkCase?>? fresh;
    try {
      final repository = ref.read(workQueueRepositoryProvider);
      fresh = await Future.wait([
        for (final workCase in reads) repository.refreshCase(workCase),
      ]);
    } catch (_) {
      // Handled below: a whole re-read, unless a newer read won.
    } finally {
      _readingChanges = false;
    }
    if (!ref.mounted) return;
    if (generation != _generation) {
      // A newer read won. Keep these cases for the next round; reading
      // them again is cheap and never stale.
      for (final entry in changed.entries) {
        _changed.putIfAbsent(entry.key, () => entry.value);
      }
      _readChangesSoon();
      return;
    }
    if (fresh == null) {
      ref.invalidateSelf();
      return;
    }
    final replaced = <String, WorkCase>{};
    for (var index = 0; index < reads.length; index++) {
      final before = reads[index];
      final after = fresh[index];
      if (after == null) {
        deleted.add(before.id); // Archived: it leaves the queue.
      } else if (after.inputRevision != before.inputRevision) {
        ref.invalidateSelf();
        return;
      } else {
        replaced[before.id] = after;
      }
    }
    _apply(current, replaced, deleted);
    if (_changed.isNotEmpty || _reloadAll) _readChangesSoon();
    _schedulePoll();
  }

  /// Swaps the re-read cases into the list as it is now (the tab may have
  /// changed meanwhile) and drops the deleted ones.
  void _apply(
    WorkQueueState read,
    Map<String, WorkCase> replaced,
    Set<String> deleted,
  ) {
    final current = state.value ?? read;
    final items = List<WorkCase>.unmodifiable([
      for (final workCase in current.items)
        if (!deleted.contains(workCase.id)) replaced[workCase.id] ?? workCase,
    ]);
    final counts = current.nextCursor == null
        ? WorkQueueCounts.fromCases(items)
        : _shift(current.counts, [
            for (final workCase in current.items)
              if (deleted.contains(workCase.id))
                (workCase, null)
              else if (replaced[workCase.id] case final after?)
                (workCase, after),
          ]);
    if (_query.isEmpty) _allWaiting = counts.waiting;
    if (deleted.contains(_selectedId)) _selectedId = null;
    state = AsyncData(
      WorkQueueState(
        items: items,
        counts: counts,
        nextCursor: current.nextCursor,
        status: _status,
        query: current.query,
        selectedId: _selectedId,
        allWaiting: _allWaiting,
      ),
    );
  }

  /// Server counts moved by the cases that changed tabs or left, for a
  /// list that does not hold every case.
  static WorkQueueCounts _shift(
    WorkQueueCounts counts,
    List<(WorkCase, WorkCase?)> changes,
  ) {
    var waiting = counts.waiting;
    var running = counts.running;
    var complete = counts.complete;
    var total = counts.total;
    void add(WorkCase workCase, int delta) {
      total += delta;
      switch (workCase.status.tab) {
        case WorkCaseStatus.waiting:
          waiting += delta;
        case WorkCaseStatus.running:
          running += delta;
        case WorkCaseStatus.complete:
          complete += delta;
        default:
          break;
      }
    }

    for (final (before, after) in changes) {
      add(before, -1);
      if (after != null) add(after, 1);
    }
    return WorkQueueCounts(
      waiting: waiting,
      running: running,
      complete: complete,
      total: total,
    );
  }

  void select(String? caseId) {
    _selectedId = caseId;
    final current = state.hasValue ? state.requireValue : null;
    if (current != null) state = AsyncData(current.select(caseId));
  }

  Future<void> loadMore() async {
    final current = state.hasValue && !state.isLoading
        ? state.requireValue
        : null;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;
    final generation = ++_generation;
    _extended = true;
    state = AsyncData(
      current.withMore(
        items: current.items,
        nextCursor: cursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(workQueueRepositoryProvider)
          .getCases(query: _query, cursor: cursor, limit: pageSize);
      // A newer load (e.g. another search) replaced the list meanwhile.
      if (!ref.mounted || generation != _generation) return;
      final items = List<WorkCase>.unmodifiable([
        ...current.items,
        ...page.items,
      ]);
      final counts = _counts(items, page.nextCursor, page.counts);
      if (_query.isEmpty) _allWaiting = counts.waiting;
      // The tab may have changed while this page was loading.
      state = AsyncData(
        current
            .withStatus(_status)
            .withMore(
              items: items,
              nextCursor: page.nextCursor,
              loadingMore: false,
              counts: counts,
              allWaiting: _allWaiting,
            ),
      );
    } catch (_) {
      // Keep what is shown; the user can press load more again.
      if (ref.mounted && generation == _generation) {
        state = AsyncData(current.withStatus(_status));
      }
    }
    // Changes that arrived while the page was loading.
    if (ref.mounted && (_changed.isNotEmpty || _reloadAll)) {
      _readChangesSoon();
    }
  }

  /// API-05. 되돌릴 수 없으므로 화면에서 확인을 받은 뒤 호출합니다.
  Future<void> acceptIncrease(WorkCase workCase) async {
    await ref.read(workQueueRepositoryProvider).acceptIncrease(workCase);
    if (!ref.mounted) return;
    // The case is gone on the server; close it before the list reloads.
    select(null);
    ref.invalidateSelf();
  }

  Future<List<SelectedDraft>> selectCandidates(
    WorkCase workCase,
    CandidateSet candidates,
    List<String> supplierIds,
  ) async {
    final drafts = await ref
        .read(workQueueRepositoryProvider)
        .selectCandidates(workCase, candidates, supplierIds);
    if (ref.mounted) {
      ref.invalidate(caseCandidatesProvider(workCase.id));
      ref.invalidateSelf();
    }
    return drafts;
  }

  /// API-07. 접수(202)되면 서버가 추출 단계로 되돌리므로 목록과 진행 단계를 다시 읽습니다.
  Future<void> resume(WorkCase workCase) async {
    await ref.read(workQueueRepositoryProvider).resume(workCase);
    if (!ref.mounted) return;
    ref.invalidate(caseProgressProvider(workCase.id));
    ref.invalidateSelf();
  }

  Future<void> start(WorkCase workCase) async {
    await ref.read(workQueueRepositoryProvider).start(workCase);
    if (ref.mounted) ref.invalidateSelf();
  }
}

/// API-02 업무 한 건. 주소로 연 업무가 지금 목록(탭·검색·페이지)에 없을 때 씁니다.
@Riverpod(retry: _noRetry)
Future<WorkCase> caseDetail(Ref ref, String caseId) =>
    ref.watch(workQueueRepositoryProvider).getCase(caseId);

/// API-03 진행 단계. 멈춘 업무(보류·추가 정보 필요)에서만 조회합니다.
@Riverpod(retry: _noRetry)
Future<CaseProgress> caseProgress(Ref ref, String caseId) =>
    ref.watch(reviewProgressRepositoryProvider).getProgress(caseId);

/// API-16 초안이 있는지. 단계만으로 알 수 없는 업무(처리 오류, 회신 연결 뒤)에서만
/// 조회해 '메일 초안 보기'를 보여 줄지 정합니다.
@Riverpod(retry: _noRetry)
Future<bool> caseHasDrafts(Ref ref, String caseId) async =>
    (await ref.watch(mailDraftRepositoryProvider).getDrafts(caseId)).isNotEmpty;

/// API-11 후보. 고를 수 있는 업무(SELECT_CANDIDATES)에서만 조회합니다.
@Riverpod(retry: _noRetry)
Future<CandidateSet> caseCandidates(Ref ref, String caseId) =>
    ref.watch(workQueueRepositoryProvider).getCandidates(caseId);

@Riverpod(retry: _noRetry)
Future<OriginalMail> originalMail(Ref ref, String mailId) =>
    ref.watch(workQueueRepositoryProvider).getOriginalMail(mailId);

/// API-26 첨부 원본. 뷰어를 닫으면 메모리에서 내려갑니다.
@Riverpod(retry: _noRetry)
Future<Uint8List> attachmentContent(
  Ref ref,
  String mailId,
  String attachmentId,
) => ref
    .watch(workQueueRepositoryProvider)
    .getAttachmentContent(mailId, attachmentId);

@Riverpod(keepAlive: true)
Stream<WorkCaseChange> workCaseChanges(Ref ref) {
  // AuthSession compares by status and email, so token refreshes do not
  // resubscribe.
  final signedIn =
      ref.watch(authSessionViewModelProvider).asData?.value.isSignedIn ?? false;
  if (!signedIn) return const Stream.empty();
  return ref.watch(workCaseChangeSourceProvider).watch();
}
