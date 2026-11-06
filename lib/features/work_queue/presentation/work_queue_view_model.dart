import "dart:async";
import "dart:typed_data";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../auth/presentation/auth_session_view_model.dart";
import "../../mail_draft/data/mail_draft_repository_impl.dart";
import "../../review_progress/data/review_progress_repository_impl.dart";
import "../data/work_case_change_source.dart";
import "../data/work_queue_repository_impl.dart";
import "../domain/candidate.dart";
import "../domain/work_case.dart";
import "../domain/work_queue_state.dart";

part "work_queue_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// 사이드바의 품목별 업무 큐와 현재 선택한 업무.
///
/// 목록 조회(API-01)는 상태를 바꾸지 않습니다. 업무를 선택해도 추출이 시작되지 않습니다.
@Riverpod(keepAlive: true, retry: _noRetry)
class WorkQueueViewModel extends _$WorkQueueViewModel {
  /// Fallback when Realtime is down or misses a change (08 §11: 15 seconds).
  /// Any reload restarts it, so it only fires after a quiet interval.
  static const pollInterval = Duration(seconds: 15);

  String? _selectedId;
  Timer? _refreshTimer;
  Timer? _poll;

  /// More pages were loaded; a poll would drop them, so it waits.
  bool _extended = false;

  /// 상태 탭(null은 전체)과 검색어. 서버(API-01 status·q)가 거릅니다.
  WorkCaseStatus? _status;
  String _query = "";

  /// counts.waiting from the last response without a search (status does
  /// not change counts), for the home summary.
  int? _allWaiting;

  @override
  Future<WorkQueueState> build() async {
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _poll?.cancel();
    });
    _extended = false;
    // Supabase says a case changed (new mail, AI step, deletion): re-read
    // the queue so only the widgets showing that case update.
    ref.listen(workCaseChangesProvider, (_, next) {
      if (next.hasValue) _refreshSoon();
    });
    final page = await ref
        .watch(workQueueRepositoryProvider)
        .getCases(status: _status, query: _query);
    _schedulePoll();
    return _fromPage(page);
  }

  WorkQueueState _fromPage(WorkQueuePage page) {
    // A case accepted elsewhere disappears; drop a selection that no longer exists.
    if (!page.items.any((workCase) => workCase.id == _selectedId)) {
      _selectedId = null;
    }
    if (_query.isEmpty) _allWaiting = page.counts.waiting;
    return WorkQueueState(
      items: page.items,
      counts: page.counts,
      nextCursor: page.nextCursor,
      status: _status,
      query: _query,
      selectedId: _selectedId,
      allWaiting: _allWaiting,
    );
  }

  void refresh() => ref.invalidateSelf();

  /// 상태 탭을 바꿉니다. null은 전체입니다.
  void setStatus(WorkCaseStatus? status) {
    if (status == _status) return;
    _status = status;
    ref.invalidateSelf();
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

  /// Replaces the first page without a loading state, so the queue does not
  /// flash. Uses the open status tab and search; a result for a filter the
  /// user has since changed is dropped. Skipped while signed out or after
  /// load more; a failure keeps what is shown and the next poll tries again.
  Future<void> _pollNow() async {
    final signedIn =
        ref.read(authSessionViewModelProvider).asData?.value.isSignedIn ??
        false;
    final current = state.hasValue && !state.isLoading
        ? state.requireValue
        : null;
    if (signedIn && current != null && !_extended && !current.loadingMore) {
      final status = _status;
      final query = _query;
      try {
        final page = await ref
            .read(workQueueRepositoryProvider)
            .getCases(status: status, query: query);
        if (!ref.mounted) return;
        if (!_extended &&
            status == _status &&
            query == _query &&
            state.hasValue &&
            !state.isLoading) {
          state = AsyncData(_fromPage(page));
        }
      } catch (_) {
        if (!ref.mounted) return;
      }
    }
    if (ref.mounted) _schedulePoll();
  }

  /// One reload for a burst of changes (e.g. one mail touching several rows).
  void _refreshSoon() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (ref.mounted) ref.invalidateSelf();
    });
  }

  void select(String? caseId) {
    _selectedId = caseId;
    final current = state.hasValue ? state.requireValue : null;
    if (current != null) state = AsyncData(current.select(caseId));
  }

  Future<void> loadMore() async {
    final current = state.hasValue ? state.requireValue : null;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;
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
          .getCases(status: _status, query: _query, cursor: cursor);
      if (!ref.mounted) return;
      state = AsyncData(
        current.withMore(
          items: List.unmodifiable([...current.items, ...page.items]),
          nextCursor: page.nextCursor,
          loadingMore: false,
        ),
      );
    } catch (_) {
      // Keep what is shown; the user can press load more again.
      if (ref.mounted) state = AsyncData(current);
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

  /// API-12. 고른 업체로 견적 요청 초안을 만들고 목록을 다시 불러옵니다.
  /// 업체별 발송 상태(drafts[].dispatch_state)를 돌려줍니다.
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

  /// API-04. 접수(202)만 확인하고 목록을 다시 불러 진행 상태를 보여 줍니다.
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

/// API-25 원문. 열기만 해서는 추출·OCR이 실행되지 않습니다.
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

/// Realtime change signal while signed in; nothing when signed out.
@Riverpod(keepAlive: true)
Stream<int> workCaseChanges(Ref ref) {
  // AuthSession compares by status and email, so token refreshes do not
  // resubscribe.
  final signedIn =
      ref.watch(authSessionViewModelProvider).asData?.value.isSignedIn ?? false;
  if (!signedIn) return const Stream.empty();
  return ref.watch(workCaseChangeSourceProvider).watch();
}
