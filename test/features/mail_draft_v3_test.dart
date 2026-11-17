import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/mail_draft_dialog.dart";
import "package:gyeonjwo_frontend/features/mail_draft/presentation/mail_draft_view_model.dart";
import "package:gyeonjwo_frontend/features/send_settings/domain/send_settings.dart";
import "package:gyeonjwo_frontend/features/send_settings/presentation/send_settings_dialog.dart";
import "package:gyeonjwo_frontend/features/send_settings/presentation/send_settings_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

MailDraft _draft(String id) => MailDraft(
  id: id,
  caseId: "case-1",
  supplierId: "supplier-$id",
  supplierName: "한라푸드 $id",
  purpose: DraftPurpose.rfq,
  recipient: "$id@example.invalid",
  subject: "견적 요청",
  body: "안녕하세요, 구매팀입니다.",
  status: DraftStatus.draft,
  inputRevision: 1,
  snapshotHash: "hash",
  settingsConfigured: true,
  approvalRequired: true,
  approvalAvailable: true,
  settingsVersion: "v1",
);

class _Drafts extends MailDraftViewModel {
  @override
  Future<List<MailDraft>> build(String caseId) async => [
    _draft("a"),
    _draft("b"),
  ];
}

class _Settings extends SendSettingsViewModel {
  @override
  Future<SendSettings> build(String scope) async => const SendSettings(
    mailboxRef: "mb",
    configured: false,
    settingsVersion: 1,
    approvals: [
      PurposeApproval(
        purpose: DraftPurpose.rfq,
        ownValue: null,
        effectiveValue: null,
      ),
    ],
    missingItems: ["견적 요청"],
    tone: MailTone.formal,
    signature: "구매팀 드림",
  );
}

Future<void> _pump(WidgetTester tester, Widget dialog) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mailDraftViewModelProvider.overrideWith2((_) => _Drafts()),
        sendSettingsViewModelProvider.overrideWith2((_) => _Settings()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(WorkspacePalette.lds),
        home: Scaffold(body: dialog),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("mail draft: LdsDialog, tabs with status, key-value header", (
    tester,
  ) async {
    await _pump(tester, const MailDraftDialog(caseId: "case-1"));
    expect(find.byType(LdsDialog), findsOneWidget);
    expect(find.text("메일 초안·발송"), findsOneWidget);
    // One tab per supplier, each with its status label.
    expect(find.text("한라푸드 a · ${DraftPurpose.rfq.label}"), findsOneWidget);
    expect(find.text(DraftStatus.draft.label), findsNWidgets(2));
    // Recipient and subject sit in a label-value table above the body.
    final table = find.byType(LdsKeyValueTable);
    expect(table, findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.text("받는 사람")),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text("안녕하세요, 구매팀입니다.")).dy,
      greaterThan(tester.getBottomLeft(table).dy),
    );
  });

  testWidgets("mail draft footer: ghost, outlined neutral, then filled", (
    tester,
  ) async {
    await _pump(tester, const MailDraftDialog(caseId: "case-1"));
    expect(find.widgetWithText(TextButton, "닫기"), findsOneWidget);
    final edit = tester.widget<LdsButton>(find.widgetWithText(LdsButton, "수정"));
    expect(edit.variant, LdsButtonVariant.outlinedNeutral);
    final approve = tester.widget<LdsButton>(
      find.widgetWithText(LdsButton, "승인 후 발송"),
    );
    expect(approve.variant, LdsButtonVariant.filled);
    // Filled last, at the right end.
    expect(
      tester.getTopRight(find.widgetWithText(LdsButton, "승인 후 발송")).dx,
      greaterThan(tester.getTopRight(find.widgetWithText(LdsButton, "수정")).dx),
    );
  });

  testWidgets("send settings: toggle rows, round tone tabs, save filled", (
    tester,
  ) async {
    await _pump(tester, const SendSettingsDialog());
    expect(find.byType(LdsDialog), findsOneWidget);
    expect(find.byType(LdsNotice), findsOneWidget);
    expect(find.byType(LdsToggle), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.widgetWithText(TextButton, "취소"), findsOneWidget);
    expect(
      tester.widget<LdsButton>(find.widgetWithText(LdsButton, "설정 저장")).variant,
      LdsButtonVariant.filled,
    );
    // 문안·서명 unfolds to the tone chips and the signature field.
    await tester.tap(find.text("문안·서명"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsRoundTabs<MailTone>), findsOneWidget);
    expect(find.byType(SegmentedButton<MailTone>), findsNothing);
    expect(find.widgetWithText(LdsTextField, "서명"), findsOneWidget);
    // Choosing a tone marks the dialog changed (cancel asks first).
    final other = MailTone.values.firstWhere((tone) => tone != MailTone.formal);
    await tester.tap(find.text(other.label));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LdsRoundTabs<MailTone>>(find.byType(LdsRoundTabs<MailTone>))
          .selected,
      other,
    );
  });
}
