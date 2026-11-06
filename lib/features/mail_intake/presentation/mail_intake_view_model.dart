import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../auth/presentation/auth_session_view_model.dart";
import "../data/mail_intake_repository_impl.dart";
import "../domain/intake_mail.dart";
import "../../work_queue/presentation/work_queue_view_model.dart";

part "mail_intake_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-009 pending intake mails. The work queue reads totalPending from here.
///
/// No Realtime signal covers intake mails (they do not touch work_cases), so
/// the list re-reads itself every [pollInterval] (08 §11 suggests 15 seconds).
@Riverpod(keepAlive: true, retry: _noRetry)
class MailIntakeViewModel extends _$MailIntakeViewModel {
  static const pollInterval = Duration(seconds: 15);

  Timer? _poll;

  @override
  Future<IntakePage> build() async {
    ref.onDispose(() => _poll?.cancel());
    final page = await ref.watch(mailIntakeRepositoryProvider).getPending();
    _schedulePoll();
    return page;
  }

  void refresh() => ref.invalidateSelf();

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(pollInterval, _pollNow);
  }

  /// Replaces the data without a loading state, so the list does not flash.
  /// A failure keeps what is shown; the next poll tries again.
  Future<void> _pollNow() async {
    final signedIn =
        ref.read(authSessionViewModelProvider).asData?.value.isSignedIn ??
        false;
    if (signedIn && state.hasValue && !state.isLoading) {
      try {
        final page = await ref.read(mailIntakeRepositoryProvider).getPending();
        if (!ref.mounted) return;
        if (!state.isLoading) state = AsyncData(page);
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
