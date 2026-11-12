import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_draft/data/mail_draft_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft_repository.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/mail_draft_view_model.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/widgets/send_policy_banner.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";

const _draft = MailDraft(
  id: "draft-1",
  caseId: "case-1",
  supplierId: "supplier-1",
  purpose: DraftPurpose.rfq,
  recipient: "supplier@example.invalid",
  subject: "견적 요청",
  body: "본문",
  status: DraftStatus.draft,
  inputRevision: 1,
  snapshotHash: "hash",
  settingsConfigured: true,
  approvalRequired: true,
  approvalAvailable: true,
  settingsVersion: "v1",
);

/// The server accepts the approval (202) but the draft never leaves DRAFT.
class _NeverSends implements MailDraftRepository {
  @override
  Future<List<MailDraft>> getDrafts(String caseId) async => const [_draft];

  @override
  Future<MailDraft> getDraft(String draftId) async => _draft;

  @override
  Future<void> approveAndSend(MailDraft draft) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Supplier names are optional; the view model falls back to the address.
class _NoQueue implements WorkQueueRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets("an accepted approval that never sends is reported after the "
      "wait instead of silently returning to the draft", (tester) async {
    final container = ProviderContainer(
      overrides: [
        mailDraftRepositoryProvider.overrideWithValue(_NeverSends()),
        workQueueRepositoryProvider.overrideWithValue(_NoQueue()),
      ],
    );
    addTearDown(container.dispose);
    final provider = mailDraftViewModelProvider("case-1");
    container.listen(provider, (previous, next) {});
    await container.read(provider.future);
    MailDraft current() => container.read(provider).requireValue.single;

    final accepted = await container.read(provider.notifier).approve(_draft);
    expect(accepted.awaitingResult, isTrue);
    expect(accepted.resultTimedOut, isFalse);

    for (var poll = 0; poll < MailDraftViewModel.maxWaitPolls; poll++) {
      await tester.pump(MailDraftViewModel.pollInterval);
    }
    expect(current().awaitingResult, isFalse);
    expect(current().resultTimedOut, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SendPolicyBanner(draft: current(), editing: false),
        ),
      ),
    );
    expect(find.textContaining("결과가 나오지 않았습니다"), findsOneWidget);

    container.read(provider.notifier).refresh();
    await tester.pump(const Duration(milliseconds: 1));
    await container.read(provider.future);
    expect(current().resultTimedOut, isFalse);
  });
}
