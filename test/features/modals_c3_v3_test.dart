import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/intake_mail.dart";
import "package:gyeonjwo_frontend/features/mail_intake/presentation/mail_intake_dialog.dart";
import "package:gyeonjwo_frontend/features/mail_intake/presentation/mail_intake_view_model.dart";
import "package:gyeonjwo_frontend/features/source_document/data/source_document_repository_impl.dart";
import "package:gyeonjwo_frontend/features/source_document/domain/source_document.dart";
import "package:gyeonjwo_frontend/features/source_document/domain/source_document_repository.dart";
import "package:gyeonjwo_frontend/features/source_document/presentation/source_document_dialog.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/supplier_register_dialog.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

class _Intake extends MailIntakeViewModel {
  @override
  Future<IntakePage> build() async => const IntakePage(
    items: [
      IntakeMail(
        mailId: "m1",
        subject: "RE: 냉동 딸기 견적 요청",
        sender: "order@b-supplier.example.com",
        receivedAt: "2026-10-19T04:10:00Z",
        bodyText: "견적 회신드립니다.",
        reason: IntakeReason.ambiguous,
        reasonDetail: "같은 품목으로 진행 중인 업무가 2건입니다.",
        attachments: ["견적서.pdf"],
        candidates: [
          CaseCandidate(
            caseId: "REQ-1",
            title: "[단가변경] 11월 냉동 딸기",
            status: "진행 중",
            itemName: "냉동 딸기",
            difference: "규격이 홀로 요청됐으나 회신은 슬라이스",
          ),
          CaseCandidate(
            caseId: "REQ-2",
            title: "[단가변경] 냉동 딸기 공급 조건",
            status: "진행 중",
          ),
        ],
        revision: 1,
      ),
    ],
    totalPending: 1,
  );
}

class _Source implements SourceDocumentRepository {
  @override
  Future<SourceDocument> getDocument(String requestId) async =>
      const SourceDocument(
        title: "[단가변경] 11월 냉동 딸기 공급단가 조정 안내",
        sender: "한라푸드 영업담당",
        recipient: "구매담당자",
        receivedAt: "2026.10.19 10:24",
        documentType: "단가변경 통보",
        paragraphs: ["기존 단가 5,000원/kg에서 5,500원/kg으로 변경을 요청드립니다."],
        highlights: ["5,500원/kg"],
        attachments: ["냉동딸기_단가변경_안내.pdf", "단가표.xlsx"],
      );
}

Future<void> _pump(WidgetTester tester, Widget dialog) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mailIntakeViewModelProvider.overrideWith(_Intake.new),
        sourceDocumentRepositoryProvider.overrideWithValue(_Source()),
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
  testWidgets("supplier register: an empty 업체명 says so in red below it", (
    tester,
  ) async {
    await _pump(tester, const SupplierRegisterDialog());
    expect(find.byType(LdsDialog), findsOneWidget);
    final name = find.byWidgetPredicate(
      (widget) => widget is LdsTextField && widget.label == "업체명",
    );
    expect(name, findsOneWidget);
    // Fields are LDS inputs: 36 tall, label above.
    expect(
      tester
          .getSize(find.descendant(of: name, matching: find.byType(TextField)))
          .height,
      LdsTextField.height,
    );
    await tester.tap(find.widgetWithText(LdsButton, "등록"));
    await tester.pumpAndSettle();
    final message = find.text("업체명을 입력해 주세요.");
    expect(message, findsOneWidget);
    expect(tester.widget<Text>(message).style!.color, LdsColors.error);
    expect(
      tester.getTopLeft(message).dy,
      greaterThan(
        tester
            .getBottomLeft(
              find.descendant(of: name, matching: find.byType(TextField)),
            )
            .dy,
      ),
    );
    // Typing a name clears it.
    await tester.enterText(
      find.descendant(of: name, matching: find.byType(TextField)),
      "한빛농산",
    );
    await tester.pumpAndSettle();
    expect(find.text("업체명을 입력해 주세요."), findsNothing);
  });

  testWidgets("source: meta lines, body, one chip per attachment", (
    tester,
  ) async {
    await _pump(tester, const SourceDocumentDialog(requestId: "m1"));
    expect(find.byType(LdsDialog), findsOneWidget);
    expect(find.text("원문·근거 보기"), findsOneWidget);
    expect(find.text("단가변경 통보"), findsOneWidget);
    expect(find.text("냉동딸기_단가변경_안내.pdf"), findsOneWidget);
    expect(find.text("단가표.xlsx"), findsOneWidget);
    expect(find.text("첨부 2개"), findsOneWidget);
    expect(find.text("연결된 메일함에서 가져온 원문입니다."), findsOneWidget);
  });

  testWidgets("intake: list card, radio candidates with a label-value table", (
    tester,
  ) async {
    await _pump(tester, const MailIntakeDialog(initialMailId: "m1"));
    expect(find.byType(LdsDialog), findsOneWidget);
    expect(find.byTooltip("새로고침"), findsOneWidget);
    expect(find.text("확인할 메일 1"), findsOneWidget);
    expect(find.text("연결할 업무 고르기"), findsOneWidget);
    expect(find.text("후보 2건"), findsOneWidget);
    expect(find.byType(LdsRadio<String>), findsNWidgets(2));
    expect(find.text("차이"), findsOneWidget);
    expect(find.text("받은 메일"), findsOneWidget);
    expect(find.text("견적서.pdf"), findsOneWidget);
    // Linking needs a chosen case; picking one enables it.
    LdsButton link() =>
        tester.widget<LdsButton>(find.widgetWithText(LdsButton, "선택한 업무에 연결"));
    expect(link().onPressed, isNull);
    await tester.tap(find.text("[단가변경] 11월 냉동 딸기"));
    await tester.pumpAndSettle();
    expect(link().onPressed, isNotNull);
    expect(
      tester
          .widget<LdsRadio<String>>(find.byType(LdsRadio<String>).first)
          .groupValue,
      "REQ-1",
    );
  });
}
