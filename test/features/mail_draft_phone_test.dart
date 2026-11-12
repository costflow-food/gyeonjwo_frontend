import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/mail_draft_dialog.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/mail_draft_view_model.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/widgets/mail_draft_footer.dart";

MailDraft _draft(String id) => MailDraft(
  id: id,
  caseId: "case-1",
  supplierId: "supplier-$id",
  supplierName: "가나다라 공급사 $id",
  purpose: DraftPurpose.rfq,
  recipient: "$id@example.invalid",
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

class _FakeDrafts extends MailDraftViewModel {
  @override
  Future<List<MailDraft>> build(String caseId) async => [
    _draft("a"),
    _draft("b"),
    _draft("c"),
  ];
}

void main() {
  Future<void> open(WidgetTester tester, {String? draftId}) async {
    // Phone: narrower than 600, so the compact layout is used.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mailDraftViewModelProvider.overrideWith2((_) => _FakeDrafts()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MailDraftDialog(caseId: "case-1", initialDraftId: draftId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("phone: the tab row slides to the draft the dialog opened on", (
    tester,
  ) async {
    await open(tester, draftId: "c");

    // The first tab has slid out; the selected one is fully on screen.
    expect(tester.getRect(find.textContaining("공급사 a")).left, lessThan(0));
    final tab = tester.getRect(find.textContaining("공급사 c"));
    expect(tab.left, greaterThanOrEqualTo(0));
    expect(tab.right, lessThanOrEqualTo(360));
  });

  testWidgets("phone: a failed validation is reported next to the buttons", (
    tester,
  ) async {
    await open(tester);
    // The app keeps the edit button off for now, so drive the footer itself.
    final footer = tester.widget<MailDraftFooter>(find.byType(MailDraftFooter));
    footer.onEdit();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, "a@example");
    await tester.pump();

    tester
        .widget<MailDraftFooter>(find.byType(MailDraftFooter))
        .onSaveRevision();
    await tester.pump();

    expect(find.text("이메일 형식을 확인해 주세요."), findsOneWidget);
    expect(find.textContaining("입력 내용을 확인해 주세요."), findsOneWidget);
  });
}
