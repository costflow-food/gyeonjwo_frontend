import "dart:async";
import "dart:typed_data";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../auth/presentation/auth_session_view_model.dart";
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
  String? _selectedId;
  Timer? _refreshTimer;

  @override
  Future<WorkQueueState> build() async {
    ref.onDispose(() => _refreshTimer?.cancel());
    // Supabase says a case changed (new mail, AI step, deletion): re-read
    // the queue so only the widgets showing that case update.
    ref.listen(workCaseChangesProvider, (_, next) {
      if (next.hasValue) _refreshSoon();
    });
    final page = await ref.watch(workQueueRepositoryProvider).getCases();
    // A case accepted elsewhere disappears; drop a selection that no longer exists.
    if (!page.items.any((workCase) => workCase.id == _selectedId)) {
      _selectedId = null;
    }
    return WorkQueueState(
      items: page.items,
      counts: page.counts,
      nextCursor: page.nextCursor,
      selectedId: _selectedId,
    );
  }

  void refresh() => ref.invalidateSelf();

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
          .getCases(cursor: cursor);
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
  Future<void> selectCandidates(
    WorkCase workCase,
    CandidateSet candidates,
    List<String> supplierIds,
  ) async {
    await ref
        .read(workQueueRepositoryProvider)
        .selectCandidates(workCase, candidates, supplierIds);
    if (!ref.mounted) return;
    ref.invalidate(caseCandidatesProvider(workCase.id));
    ref.invalidateSelf();
  }

  /// API-04. 접수(202)만 확인하고 목록을 다시 불러 진행 상태를 보여 줍니다.
  Future<void> start(WorkCase workCase) async {
    await ref.read(workQueueRepositoryProvider).start(workCase);
    if (ref.mounted) ref.invalidateSelf();
  }
}

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
