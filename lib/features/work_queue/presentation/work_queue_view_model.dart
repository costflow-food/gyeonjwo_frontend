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
import "../domain/task_group.dart";
import "../domain/work_case.dart";
import "../domain/work_queue_repository.dart";
import "../domain/work_queue_state.dart";

part "work_queue_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
class WorkQueueViewModel extends _$WorkQueueViewModel {
  /// Fallback when Realtime is down or misses a change. Any reload restarts
  /// it, so it only fires after a quiet interval. It waits while the browser
  /// tab is hidden.
  ///
  /// 08 §11 suggests 15 seconds, but one poll re-reads every page (up to
  /// [maxPages] requests) and Realtime already covers the usual cases: a
  /// changed case is re-read alone and every (re)connect asks for a whole
  /// re-read. So the fallback runs once a minute.
  static const pollInterval = Duration(seconds: 60);

  /// After a failed load the queue tries again this soon (the 15 seconds of
  /// 08 §11), so an error does not stay for a whole [pollInterval].
  static const retryInterval = Duration(seconds: 15);

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

  /// The search whose list is on screen; null before the first list. A load
  /// for another search shows its first page at once ([_loadRest] reads the
  /// rest); a reload of the same search swaps the whole list in one step,
  /// so a long list never shrinks to one page and grows back.
  String? _listedQuery;

  /// [_loadRest] is still reading the pages after the first one. Unlike
  /// [WorkQueueState.loadingMore] it is not set by "더 불러오기", and a
  /// reload clears it.
  bool _loadingRest = false;
  bool get loadingRest => _loadingRest;

  /// More pages were loaded; a poll would drop them, so it waits.
  bool _extended = false;

  /// 상태 탭(null은 전체)은 받아 둔 목록을 화면에서 거릅니다. 검색어는
  /// 메일 제목까지 보는 서버(API-01 q)가 거릅니다.
  TaskGroup? _status;
  String _query = "";

  /// counts.confirm from the last list without a search (the tab does not
  /// change counts), for the home summary.
  int? _allConfirm;

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
    _loadingRest = false;
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
    final generation = _generation;
    final query = _query;
    final repository = ref.watch(workQueueRepositoryProvider);
    var failed = false;
    try {
      if (_listedQuery == query) {
        final page = await _fetchAll(repository);
        return _fromPage(page);
      }
      final first = await repository.getCases(query: query, limit: pageSize);
      if (generation != _generation || query != _query) {
        // A newer load took over and this result is dropped: leave the
        // selection and the home summary to that load.
        return WorkQueueState(
          items: first.items,
          counts: first.counts,
          nextCursor: first.nextCursor,
          query: query,
        );
      }
      _listedQuery = query;
      if (first.nextCursor == null) return _fromPage(first);
      // After this build's result is in [state] (a timer runs after every
      // pending microtask), so the rest lands on top of the first page.
      _loadingRest = true;
      Timer.run(() => _loadRest(generation, query, first));
      final shown = _fromPage(first, keepSelection: true);
      return shown.withMore(
        items: shown.items,
        nextCursor: shown.nextCursor,
        // Blocks polls, changed-case reads and "더 불러오기" until the rest
        // is in, and shows the spinner under the list.
        loadingMore: true,
      );
    } catch (_) {
      failed = true;
      // Once the error is in [state].
      Timer.run(() => _endLoadingMore(generation));
      rethrow;
    } finally {
      // Also after a failed first load, so the queue recovers by itself.
      _schedulePoll(failed: failed);
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

  /// A failed reload keeps the previous list on screen. If that list was
  /// still waiting for its other pages, nobody reads them any more
  /// ([_loadRest] stopped for the reload), so end that state: "더 불러오기"
  /// and changed-case reads work again. The error stays for the retry.
  void _endLoadingMore(int generation) {
    if (!ref.mounted || generation != _generation) return;
    if (state.isLoading || !state.hasError || !state.hasValue) return;
    final shown = state.requireValue;
    if (!shown.loadingMore) return;
    final error = state.error!;
    final stackTrace = state.stackTrace ?? StackTrace.current;
    state = AsyncData(
      shown.withMore(
        items: shown.items,
        nextCursor: shown.nextCursor,
        loadingMore: false,
      ),
    );
    // Keeps the value just set.
    state = AsyncError(error, stackTrace);
  }

  /// Reads the pages after [first] behind the list that already shows it,
  /// then adds them in one step so rows move at most once. The tab counts
  /// are the server's until every case is in hand ([_counts]). A failed
  /// page keeps the pages read so far; "더 불러오기" continues from there.
  Future<void> _loadRest(
    int generation,
    String query,
    WorkQueuePage first,
  ) async {
    // A newer load (another search, a refresh) took over: stop reading.
    bool stale() =>
        !ref.mounted || generation != _generation || query != _query;
    if (stale()) return;
    final repository = ref.read(workQueueRepositoryProvider);
    final items = [...first.items];
    var cursor = first.nextCursor;
    try {
      for (var pages = 1; cursor != null && pages < maxPages; pages++) {
        final page = await repository.getCases(
          query: query,
          cursor: cursor,
          limit: pageSize,
        );
        if (stale()) return;
        items.addAll(page.items);
        cursor = page.nextCursor;
      }
    } catch (_) {
      if (stale()) return;
    }
    _loadingRest = false;
    // A reload has started; its list replaces this one.
    final current = state.hasValue && !state.isLoading
        ? state.requireValue
        : null;
    if (current == null) return;
    final all = List<WorkCase>.unmodifiable(items);
    final counts = _counts(all, cursor, first.counts);
    if (query.isEmpty) _allConfirm = counts.confirm;
    if (!all.any((workCase) => workCase.id == _selectedId)) _selectedId = null;
    // The tab or the selection may have changed meanwhile.
    state = AsyncData(
      current
          .withStatus(_status)
          .select(_selectedId)
          .withMore(
            items: all,
            nextCursor: cursor,
            loadingMore: false,
            counts: counts,
            allConfirm: _allConfirm,
          ),
    );
    // Changes that arrived while the pages were loading.
    if (_changed.isNotEmpty || _reloadAll) _readChangesSoon();
    _schedulePoll();
  }

  /// Tab counts from the cases in hand, by [taskGroupOf]. The server counts
  /// by the old tabs only, so with cases still on the server only its total
  /// is used; 확인 필요·진행 중 then count the cases in hand.
  static WorkQueueCounts _counts(
    List<WorkCase> items,
    String? nextCursor,
    WorkQueueCounts server,
  ) => WorkQueueCounts.fromCases(
    items,
    serverTotal: nextCursor == null ? null : server.total,
  );

  WorkQueueState _fromPage(WorkQueuePage page, {bool keepSelection = false}) {
    // A case accepted elsewhere disappears; drop a selection that no longer
    // exists. With pages still on the way ([_loadRest]) it may be in those.
    if (!keepSelection &&
        !page.items.any((workCase) => workCase.id == _selectedId)) {
      _selectedId = null;
    }
    final counts = _counts(page.items, page.nextCursor, page.counts);
    if (_query.isEmpty) _allConfirm = counts.confirm;
    return WorkQueueState(
      items: page.items,
      counts: counts,
      nextCursor: page.nextCursor,
      status: _status,
      query: _query,
      selectedId: _selectedId,
      allConfirm: _allConfirm,
    );
  }

  void refresh() => ref.invalidateSelf();

  /// 상태 탭을 바꿉니다. null은 전체입니다. 받아 둔 목록을 거를 뿐이라
  /// 서버를 다시 부르지 않습니다.
  void setStatus(TaskGroup? status) {
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

  void _schedulePoll({bool failed = false}) {
    _poll?.cancel();
    _poll = Timer(failed ? retryInterval : pollInterval, _pollNow);
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
    if (signedIn && failed && !state.hasValue) {
      // Nothing on screen: a load shows the first page after one request,
      // and it schedules the next poll.
      ref.invalidateSelf();
      return;
    }
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
        if (applied) {
          _listedQuery = _query;
          state = AsyncData(_fromPage(page));
        }
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
    if (ref.mounted) {
      _schedulePoll(failed: state.hasError && !state.isLoading);
    }
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
    final gone = current.items.length - items.length;
    final counts = WorkQueueCounts.fromCases(
      items,
      serverTotal: current.nextCursor == null
          ? null
          : current.counts.total - gone,
    );
    if (_query.isEmpty) _allConfirm = counts.confirm;
    if (deleted.contains(_selectedId)) _selectedId = null;
    state = AsyncData(
      WorkQueueState(
        items: items,
        counts: counts,
        nextCursor: current.nextCursor,
        status: _status,
        query: current.query,
        selectedId: _selectedId,
        allConfirm: _allConfirm,
      ),
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
    if (current.query != _query) {
      // The list of the previous search is still shown because the load
      // for the new one failed; its cursor is not for this search.
      ref.invalidateSelf();
      return;
    }
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
      if (_query.isEmpty) _allConfirm = counts.confirm;
      // Every case is in hand within what one poll reads: polls can run
      // again without dropping anything.
      if (page.nextCursor == null && items.length <= maxPages * pageSize) {
        _extended = false;
      }
      // The tab may have changed while this page was loading.
      state = AsyncData(
        current
            .withStatus(_status)
            .withMore(
              items: items,
              nextCursor: page.nextCursor,
              loadingMore: false,
              counts: counts,
              allConfirm: _allConfirm,
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
