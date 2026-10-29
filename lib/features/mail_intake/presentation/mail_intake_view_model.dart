import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/mail_intake_repository_impl.dart";
import "../domain/intake_mail.dart";
import "../../work_queue/presentation/work_queue_view_model.dart";

part "mail_intake_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-009 pending intake mails. The work queue reads totalPending from here.
@Riverpod(keepAlive: true, retry: _noRetry)
class MailIntakeViewModel extends _$MailIntakeViewModel {
  @override
  Future<IntakePage> build() =>
      ref.watch(mailIntakeRepositoryProvider).getPending();

  void refresh() => ref.invalidateSelf();

  /// Reloads afterwards even on a conflict, so a mail another user already
  /// handled drops out of the list.
  Future<void> resolve(
    IntakeMail mail,
    IntakeResolution resolution, {
    String? targetCaseId,
    String? reason,
    required String idempotencyKey,
  }) async {
    try {
      await ref
          .read(mailIntakeRepositoryProvider)
          .resolve(
            mail,
            resolution,
            targetCaseId: targetCaseId,
            reason: reason,
            idempotencyKey: idempotencyKey,
          );
      if (ref.mounted) ref.invalidate(workQueueRequestsProvider);
    } finally {
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}
