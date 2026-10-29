import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/mail_draft_repository_impl.dart";
import "../domain/mail_draft.dart";

part "mail_draft_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-007 drafts of one case. Polls while a send is in progress.
@Riverpod(keepAlive: true, retry: _noRetry)
class MailDraftViewModel extends _$MailDraftViewModel {
  /// 08 suggests about 3 seconds for progress polling.
  static const pollInterval = Duration(seconds: 3);

  Timer? _poll;

  @override
  Future<List<MailDraft>> build(String caseId) async {
    ref.onDispose(() => _poll?.cancel());
    final drafts = await ref
        .watch(mailDraftRepositoryProvider)
        .getDrafts(caseId);
    _schedulePoll(drafts);
    return drafts;
  }

  void refresh() => ref.invalidateSelf();

  Future<MailDraft> revise(
    MailDraft draft,
    DraftRevisionInput input, {
    required String idempotencyKey,
  }) async {
    final revised = await ref
        .read(mailDraftRepositoryProvider)
        .createRevision(draft, input, idempotencyKey: idempotencyKey);
    _replace(draft.id, revised);
    return revised;
  }

  Future<MailDraft> approve(
    MailDraft draft, {
    required String idempotencyKey,
  }) async {
    final sending = await ref
        .read(mailDraftRepositoryProvider)
        .approveAndSend(draft, idempotencyKey: idempotencyKey);
    _replace(draft.id, sending);
    return sending;
  }

  Future<MailDraft> reconcile(
    MailDraft draft, {
    required String idempotencyKey,
  }) async {
    final checked = await ref
        .read(mailDraftRepositoryProvider)
        .reconcile(draft, idempotencyKey: idempotencyKey);
    _replace(draft.id, checked);
    return checked;
  }

  void _replace(String oldId, MailDraft next) {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    final drafts = List<MailDraft>.unmodifiable([
      for (final draft in current) draft.id == oldId ? next : draft,
    ]);
    state = AsyncData(drafts);
    _schedulePoll(drafts);
  }

  void _schedulePoll(List<MailDraft> drafts) {
    _poll?.cancel();
    if (!drafts.any((draft) => draft.status == DraftStatus.sending)) return;
    _poll = Timer(pollInterval, () {
      if (ref.mounted) ref.invalidateSelf();
    });
  }
}
