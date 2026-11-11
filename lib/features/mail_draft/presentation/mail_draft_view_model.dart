import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../work_queue/data/work_queue_repository_impl.dart";
import "../data/mail_draft_repository_impl.dart";
import "../domain/mail_draft.dart";

part "mail_draft_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// SCR-007 drafts of one case. While a draft is sending, or an accepted
/// approval or reconcile has no visible result yet, re-reads it with API-17.
@Riverpod(retry: _noRetry)
class MailDraftViewModel extends _$MailDraftViewModel {
  /// 08 suggests about 3 seconds for progress polling.
  static const pollInterval = Duration(seconds: 3);

  /// Stop waiting for an accepted request after about a minute.
  static const maxWaitPolls = 20;

  Timer? _poll;

  /// supplier_id → name from the API-11 candidates.
  Map<String, String> _names = const {};

  /// Accepted (202) drafts whose API-17 status has not moved yet → polls.
  final Map<String, int> _awaiting = {};

  /// Drafts whose accepted request showed no result within [maxWaitPolls].
  final Set<String> _timedOut = {};

  @override
  Future<List<MailDraft>> build(String caseId) async {
    ref.onDispose(() => _poll?.cancel());
    final drafts = await ref
        .watch(mailDraftRepositoryProvider)
        .getDrafts(caseId);
    _names = await _supplierNames(caseId);
    final named = List<MailDraft>.unmodifiable(drafts.map(_named));
    _schedulePoll(named);
    return named;
  }

  void refresh() {
    _timedOut.clear();
    ref.invalidateSelf();
  }

  Future<MailDraft> revise(MailDraft draft, DraftRevisionInput input) async {
    final revised = await ref
        .read(mailDraftRepositoryProvider)
        .createRevision(draft, input);
    final next = _named(revised);
    _replace(draft.id, next);
    return next;
  }

  Future<MailDraft> approve(MailDraft draft) => _submit(
    draft,
    () => ref.read(mailDraftRepositoryProvider).approveAndSend(draft),
  );

  Future<MailDraft> reconcile(MailDraft draft) => _submit(
    draft,
    () => ref.read(mailDraftRepositoryProvider).reconcile(draft),
  );

  Future<MailDraft> withdraw(MailDraft draft, {required String reason}) =>
      _submit(
        draft,
        () => ref
            .read(mailDraftRepositoryProvider)
            .withdraw(draft, reason: reason),
      );

  Future<MailDraft> _submit(
    MailDraft draft,
    Future<void> Function() request,
  ) async {
    await request();
    _timedOut.remove(draft.id);
    MailDraft? latest;
    try {
      latest = await ref.read(mailDraftRepositoryProvider).getDraft(draft.id);
    } catch (_) {
      // Accepted; polling reads the result.
    }
    if (latest == null || latest.status == draft.status) {
      _awaiting[draft.id] = 0;
    }
    final next = _named(latest ?? draft);
    _replace(draft.id, next);
    return next;
  }

  Future<Map<String, String>> _supplierNames(String caseId) async {
    try {
      final set = await ref
          .read(workQueueRepositoryProvider)
          .getCandidates(caseId);
      return {
        for (final candidate in set.candidates)
          candidate.supplierId: candidate.name,
      };
    } catch (_) {
      // Not ready or unavailable: the recipient address is shown instead.
      return const {};
    }
  }

  MailDraft _named(MailDraft draft) => draft.copyWith(
    supplierName: _names[draft.supplierId],
    awaitingResult: _awaiting.containsKey(draft.id),
    resultTimedOut: _timedOut.contains(draft.id),
  );

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

  bool _watching(MailDraft draft) =>
      draft.status == DraftStatus.sending || _awaiting.containsKey(draft.id);

  void _schedulePoll(List<MailDraft> drafts) {
    _poll?.cancel();
    if (!drafts.any(_watching)) return;
    _poll = Timer(pollInterval, _pollOnce);
  }

  Future<void> _pollOnce() async {
    final current = state.asData?.value;
    if (!ref.mounted || current == null) return;
    final repository = ref.read(mailDraftRepositoryProvider);
    for (final draft in current.where(_watching)) {
      MailDraft? latest;
      try {
        latest = await repository.getDraft(draft.id);
      } catch (_) {
        // Try again on the next poll.
      }
      if (!ref.mounted) return;
      final attempts = _awaiting[draft.id];
      if (attempts != null) {
        if (latest != null && latest.status != draft.status) {
          _awaiting.remove(draft.id);
        } else if (attempts + 1 >= maxWaitPolls) {
          // The wait ends, but the screen says so: the request may not have
          // been carried out (no send permission, changed settings, ...).
          _awaiting.remove(draft.id);
          _timedOut.add(draft.id);
        } else {
          _awaiting[draft.id] = attempts + 1;
        }
      }
      _replace(draft.id, _named(latest ?? draft));
    }
    final drafts = state.asData?.value;
    if (ref.mounted && drafts != null) _schedulePoll(drafts);
  }
}
