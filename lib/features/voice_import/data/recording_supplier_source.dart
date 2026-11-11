import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../mail_draft/data/mail_draft_repository_impl.dart";
import "../../mail_draft/domain/mail_draft.dart";
import "../../purchase_review/data/purchase_review_repository_impl.dart";
import "../../work_queue/data/work_queue_repository_impl.dart";
import "../../work_queue/domain/work_case.dart";
import "../domain/recording_supplier.dart";

/// [responded] is the case's reply count (reply_summary), used to check the
/// per-supplier reply marks before showing them.
typedef RecordingSupplierQuery = ({String caseId, int? responded});

/// The query for a case's recording suppliers, or null when the queue already
/// says no 견적 요청 went out. A case read on its own (API-02) has no reply
/// summary: its query has no count, and the suppliers decide.
RecordingSupplierQuery? recordingSupplierQueryOf(WorkCase workCase) {
  final replies = workCase.replySummary;
  if (replies != null && !replies.visible) return null;
  return (caseId: workCase.id, responded: replies?.responded);
}

// A failed read shows its error and 다시 시도 at once, like the other screens.
Duration? _noRetry(int retryCount, Object error) => null;

/// 견적 요청(RFQ)이 발송된 업체. 이름은 후보 목록, 회신 여부는 견적에서 읽습니다.
final recordingSuppliersProvider = FutureProvider.autoDispose
    .family<List<RecordingSupplier>, RecordingSupplierQuery>((
      ref,
      query,
    ) async {
      final caseId = query.caseId;
      final drafts = await ref
          .watch(mailDraftRepositoryProvider)
          .getDrafts(caseId);
      // One row per supplier, in the order the requests were written.
      final sent = <String, MailDraft>{};
      for (final draft in drafts) {
        if (draft.purpose == DraftPurpose.rfq &&
            draft.status == DraftStatus.sent) {
          sent.putIfAbsent(draft.supplierId, () => draft);
        }
      }
      if (sent.isEmpty) return const [];

      var names = const <String, String>{};
      try {
        final set = await ref
            .watch(workQueueRepositoryProvider)
            .getCandidates(caseId);
        names = {
          for (final candidate in set.candidates)
            candidate.supplierId: candidate.name,
        };
      } catch (_) {
        // The address is shown instead.
      }

      // Suppliers with a quote have replied. Shown only when that agrees with
      // the case's own reply count; otherwise a "회신 전" mark could be wrong.
      Set<String>? replied;
      try {
        final quotes = await ref
            .watch(purchaseReviewRepositoryProvider)
            .getQuotes(caseId);
        final withQuote = {
          for (final quote in quotes)
            if (!quote.isIncumbent && sent.containsKey(quote.supplierId))
              quote.supplierId,
        };
        if (query.responded == withQuote.length) replied = withQuote;
      } catch (_) {
        // Unknown: no marks.
      }

      return [
        for (final draft in sent.values)
          RecordingSupplier(
            supplierId: draft.supplierId,
            name: names[draft.supplierId] ?? draft.recipient,
            email: draft.recipient,
            replied: replied?.contains(draft.supplierId),
          ),
      ];
    }, retry: _noRetry);
