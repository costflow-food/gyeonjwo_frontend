import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/app_visibility.dart";
import "../../auth/presentation/auth_session_view_model.dart";
import "../data/mail_intake_repository_impl.dart";
import "../domain/intake_mail.dart";
import "../domain/mail_intake_repository.dart";
import "../../work_queue/presentation/work_queue_view_model.dart";

part "mail_intake_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-009 pending intake mails. The work queue reads totalPending from here.
///
/// No Realtime signal covers intake mails (they do not touch work_cases), so
/// the list re-reads itself every [pollInterval] (08 §11 suggests 15 seconds),
/// except while the browser tab is hidden.
@Riverpod(keepAlive: true, retry: _noRetry)
class MailIntakeViewModel extends _$MailIntakeViewModel {
  static const pollInterval = Duration(seconds: 15);

  /// Pages one read covers at most. A read covers as many pages as
  /// "더 불러오기" has shown, so a poll does not drop them.
  static const maxPages = 10;

  Timer? _poll;

  /// A poll came due while the tab was hidden; it runs when the tab shows.
  bool _pollWaiting = false;

  /// Pages shown, first page included.
  int _pages = 1;

  /// Bumped by every read that replaces or extends the list. A response is
  /// applied only while its generation is still the newest, so a late
  /// response never overwrites a newer list.
  int _generation = 0;

  @override
  Future<IntakePage> build() async {
    ref.onDispose(() => _poll?.cancel());
    ref.listen(appVisibleProvider, (_, visible) {
      if (visible && _pollWaiting) {
        _pollWaiting = false;
        _pollNow();
      }
    });
    _generation++;
    try {
      return await _fetch(ref.watch(mailIntakeRepositoryProvider));
    } finally {
      // Also after a failed first load, so the list recovers by itself (S1-7).
      _schedulePoll();
    }
  }

  void refresh() => ref.invalidateSelf();

  /// The first [_pages] pages; the total comes from the first page.
  Future<IntakePage> _fetch(MailIntakeRepository repository) async {
    final first = await repository.getPending();
    final items = [...first.items];
    var cursor = first.nextCursor;
    for (var read = 1; cursor != null && read < _pages; read++) {
      final page = await repository.getPending(cursor: cursor);
      items.addAll(_unseen(items, page.items));
      cursor = page.nextCursor;
    }
    return IntakePage(
      items: List.unmodifiable(items),
      totalPending: first.totalPending,
      nextCursor: cursor,
    );
  }

  static Iterable<IntakeMail> _unseen(
    List<IntakeMail> shown,
    List<IntakeMail> next,
  ) {
    final ids = {for (final mail in shown) mail.mailId};
    return next.where((mail) => !ids.contains(mail.mailId));
  }

  /// "더 불러오기". A failure keeps what is shown; the user can press again.
  Future<void> loadMore() async {
    final current = state.hasValue && !state.isLoading
        ? state.requireValue
        : null;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;
    final generation = ++_generation;
    state = AsyncData(current.withLoadingMore(true));
    try {
      final page = await ref
          .read(mailIntakeRepositoryProvider)
          .getPending(cursor: cursor);
      if (!ref.mounted || generation != _generation) return;
      if (_pages < maxPages) _pages++;
      state = AsyncData(
        IntakePage(
          items: List.unmodifiable([
            ...current.items,
            ..._unseen(current.items, page.items),
          ]),
          totalPending: page.totalPending,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(current);
      }
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(pollInterval, _pollNow);
  }

  /// Replaces the data without a loading state, so the list does not flash.
  /// A failure keeps what is shown; the next poll tries again. After a
  /// failed load it keeps trying until the list shows. Waits while the tab
  /// is hidden or more mails are loading.
  Future<void> _pollNow() async {
    if (!ref.read(appVisibleProvider)) {
      _pollWaiting = true;
      return;
    }
    final signedIn =
        ref.read(authSessionViewModelProvider).asData?.value.isSignedIn ??
        false;
    final loadingMore = state.value?.loadingMore ?? false;
    if (signedIn &&
        (state.hasValue || state.hasError) &&
        !state.isLoading &&
        !loadingMore) {
      final generation = ++_generation;
      try {
        final page = await _fetch(ref.read(mailIntakeRepositoryProvider));
        if (!ref.mounted) return;
        if (generation == _generation) state = AsyncData(page);
      } catch (_) {
        if (!ref.mounted) return;
      }
    }
    if (ref.mounted) _schedulePoll();
  }

  /// Reloads afterwards even on a conflict, so a mail another user already
  /// handled drops out of the list.
  Future<void> resolve(
    IntakeMail mail,
    IntakeResolution resolution, {
    String? targetCaseId,
    String? reason,
  }) async {
    try {
      await ref
          .read(mailIntakeRepositoryProvider)
          .resolve(
            mail,
            resolution,
            targetCaseId: targetCaseId,
            reason: reason,
          );
      if (ref.mounted) ref.invalidate(workQueueViewModelProvider);
    } finally {
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}
