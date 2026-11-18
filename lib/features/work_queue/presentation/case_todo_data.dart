import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../mail_draft/data/mail_draft_repository_impl.dart";
import "../../mail_draft/domain/mail_draft.dart";
import "../../purchase_review/data/purchase_review_repository_impl.dart";
import "../../purchase_review/domain/purchase_review.dart";

// Tasks 상세 '지금 할 일' 상자의 표에 쓰는 자료. 상자는 이 자료가 없거나
// 읽지 못하면 표를 빼고 문장·버튼만 보입니다.

Duration? _noRetry(int retryCount, Object error) => null;

/// API-16 업무의 메일 초안(보낼 초안·발송 결과 표).
final caseMailDraftsProvider = FutureProvider.autoDispose
    .family<List<MailDraft>, String>(
      (ref, caseId) => ref.watch(mailDraftRepositoryProvider).getDrafts(caseId),
      retry: _noRetry,
    );

/// API-12 검토 카드(구매안 비교·확정 결과 표).
final caseReviewCardProvider = FutureProvider.autoDispose
    .family<ReviewCard, String>(
      (ref, caseId) async =>
          (await ref.watch(purchaseReviewRepositoryProvider).getReview(caseId))
              .card,
      retry: _noRetry,
    );
