import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/purchase_review/domain/purchase_review.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/case_todo_data.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/attachment_viewer.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/case_progress.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/task_row.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/work_case_panel.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

WorkCase _case(
  String status,
  String step, {
  String message = "",
  List<String> actions = const [],
  int attachments = 0,
  String? item = "냉동 딸기",
}) => WorkCase(
  id: "c1",
  initialMailId: "m1",
  title: "한라푸드",
  sender: "sales@halla.example",
  senderName: "한라푸드 영업",
  receivedAt: "2026-10-19T02:10:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: message,
  inputRevision: 1,
  attachmentCount: attachments,
  itemName: item,
  allowedActions: actions,
);

const _pdf = MailAttachment(
  id: "a1",
  filename: "단가표.pdf",
  mimeType: "application/pdf",
  sizeBytes: 140 * 1024,
);

class _Mail implements WorkQueueRepository {
  _Mail({this.attachments = const []});

  final List<MailAttachment> attachments;

  @override
  Future<OriginalMail> getOriginalMail(String mailId) async => OriginalMail(
    id: "m1",
    subject: "[단가인상] 냉동 딸기 IQF 홀 10kg 단가 조정",
    sender: "한라푸드 영업담당 <sales@halla.example>",
    recipients: const ["buyer@example.invalid"],
    receivedAt: "2026-10-19T02:10:00Z",
    bodyText: "11월 21일 출고분부터 단가를 조정하고자 합니다.",
    attachments: attachments,
  );

  @override
  Future<Uint8List> getAttachmentContent(
    String mailId,
    String attachmentId,
  ) async => Uint8List(4);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ReviewCard _card() => const ReviewCard(
  caseId: "c1",
  reviewRevision: 1,
  inputRevision: 1,
  isStale: false,
  outcome: ReviewOutcome.optionsReady,
  plans: [
    ResponsePlan(
      planId: "keep",
      planType: "KEEP",
      validationStatus: "VALID",
      allocations: [],
      totalAmount: "5800000",
    ),
    ResponsePlan(
      planId: "switch",
      planType: "SWITCH",
      validationStatus: "VALID",
      allocations: [],
      totalAmount: "5400000",
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  WorkCase workCase, {
  List<MailAttachment> attachments = const [],
  VoidCallback? onNext,
  List<MailDraft> drafts = const [],
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = const Size(1100, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: WorkCasePanel(workCase: workCase, onNext: onNext),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workQueueRepositoryProvider.overrideWithValue(
          _Mail(attachments: attachments),
        ),
        // Supply draft fixtures when testing send results.
        caseHasDraftsProvider("c1").overrideWith((ref) async => false),
        caseMailDraftsProvider("c1").overrideWith((ref) async => drafts),
        caseReviewCardProvider("c1").overrideWith((ref) async => _card()),
        caseProgressProvider("c1").overrideWith(
          (ref) async => const CaseProgress(
            caseId: "c1",
            status: "Pending",
            processingStep: "FAILED",
            inputRevision: 1,
          ),
        ),
        pdfDocumentViewProvider.overrideWithValue(
          (bytes, name) => const Center(child: Text("PDF 페이지")),
        ),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CaseStepBar _bar(WidgetTester tester) =>
    tester.widget<CaseStepBar>(find.byType(CaseStepBar));

Finder _inTodo(Finder finder) =>
    find.descendant(of: find.byType(TodoBox), matching: finder);

void main() {
  for (final name in <String?>[null, '', '거래처 A']) {
    testWidgets('send result email uses the wide value cell: $name', (
      tester,
    ) async {
      const recipient = 'buyer+20261120@example.invalid';
      await _pump(
        tester,
        _case('Pending', 'FAILED'),
        drafts: [
          MailDraft(
            id: 'draft-1',
            caseId: 'c1',
            supplierId: 'supplier-1',
            purpose: DraftPurpose.rfq,
            recipient: recipient,
            subject: '견적 요청',
            body: '견적을 부탁드립니다.',
            status: DraftStatus.sent,
            inputRevision: 1,
            snapshotHash: 'snapshot',
            settingsConfigured: true,
            supplierName: name,
          ),
        ],
      );
      final table = find.byType(TodoTable);
      final email = find.descendant(of: table, matching: find.text(recipient));
      final status = find.descendant(of: table, matching: find.text('발송됨'));
      expect(email, findsOneWidget);
      expect(
        find.descendant(
          of: table,
          matching: find.text(name == null || name.isEmpty ? '수신인' : name),
        ),
        findsOneWidget,
      );
      expect(tester.widget<Text>(email).maxLines, 1);
      expect(tester.getSize(email).width, greaterThan(TodoTable.labelWidth));
      expect(tester.getSize(email).height, lessThan(30));
      expect(
        tester.getTopLeft(status).dx,
        greaterThan(tester.getTopRight(email).dx),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("header, progress with 지금 할 일, then the mail card", (
    tester,
  ) async {
    await _pump(
      tester,
      _case("Running", "WAITING_REPLY", message: "거래처 회신 대기"),
    );
    // Header: subject, then [label] · supplier · 접수 time. No item line,
    // no buttons on the right.
    // In the header and again on the mail card, as in the design.
    expect(find.text("[단가인상] 냉동 딸기 IQF 홀 10kg 단가 조정"), findsNWidgets(2));
    expect(find.text("냉동 딸기"), findsNothing);
    expect(find.widgetWithText(TaskStatusLabel, "진행 중"), findsOneWidget);
    expect(find.text("접수 2026.10.19 11:10"), findsOneWidget);
    expect(find.widgetWithText(LdsButton, "원문 보기"), findsNothing);
    expect(find.widgetWithText(LdsButton, "메일 초안"), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    // Five steps; replies are step 4 (견적 요청·회신).
    expect(caseStepLabels, ["접수", "정보 추출", "후보 찾기", "견적 요청·회신", "검토 카드"]);
    expect(_bar(tester).stage!.index, 4);
    expect(find.text("진행 상황"), findsOneWidget);

    // 지금 할 일 (G): the situation, its state on the right, nothing to do.
    expect(_inTodo(find.text("거래처 회신을 모으고 있어요")), findsOneWidget);
    expect(_inTodo(find.widgetWithText(LdsTag, "견적 수집 중")), findsOneWidget);
    expect(_inTodo(find.text(TodoBox.idleText)), findsOneWidget);
    // The drafts moved from the header into the box.
    expect(_inTodo(find.widgetWithText(LdsButton, "메일 초안 보기")), findsOneWidget);

    // 받은 메일 · 근거 자료 below, folded to one line, no recipients.
    expect(find.text("받은 메일 · 근거 자료"), findsOneWidget);
    expect(find.text("처음 받은 요청 내용이에요"), findsOneWidget);
    expect(find.text("한라푸드 영업담당 · sales@halla.example"), findsOneWidget);
    expect(find.text("받는 사람"), findsNothing);
    expect(
      tester.getTopLeft(find.text("받은 메일 · 근거 자료")).dy,
      greaterThan(tester.getBottomLeft(find.byType(TodoBox)).dy),
    );
    final snippet = tester.widget<Text>(
      find.text("11월 21일 출고분부터 단가를 조정하고자 합니다."),
    );
    expect(snippet.maxLines, 1);
    // Unfolds on a tap.
    await tester.tap(find.text("한라푸드").last);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SelectableText, "11월 21일 출고분부터 단가를 조정하고자 합니다."),
      findsOneWidget,
    );
  });

  testWidgets("not started: 검토 시작 with 수용하기 kept (결정 c)", (tester) async {
    await _pump(
      tester,
      _case(
        "Waiting",
        "PENDING_START",
        actions: [WorkCaseAction.start, WorkCaseAction.acceptIncrease],
      ),
    );
    expect(_bar(tester).stage!.index, 1);
    expect(find.widgetWithText(TaskStatusLabel, "대기"), findsOneWidget);
    expect(_inTodo(find.text("메일을 받았어요")), findsOneWidget);
    expect(_inTodo(find.text("원문을 확인하면 검토를 시작해요.")), findsOneWidget);
    expect(_inTodo(find.text("10.19 11:10")), findsOneWidget);
    expect(_inTodo(find.text("없음")), findsOneWidget);
    final start = find.widgetWithText(LdsButton, "검토 시작");
    expect(tester.widget<LdsButton>(start).variant, LdsButtonVariant.filled);
    final accept = find.widgetWithText(LdsButton, "수용하기");
    expect(tester.widget<LdsButton>(accept).variant, LdsButtonVariant.outlined);
    expect(find.text("다른 대안 찾기"), findsNothing);
    // The mail is open and invites the reading.
    expect(find.text("받은 메일"), findsWidgets);
    expect(find.text("읽고 검토를 시작하세요"), findsOneWidget);
    expect(
      find.widgetWithText(SelectableText, "11월 21일 출고분부터 단가를 조정하고자 합니다."),
      findsOneWidget,
    );

    // 수용하기 keeps its confirmation.
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(find.text("인상을 수용하시겠습니까?"), findsOneWidget);
  });

  testWidgets("a drafted request is approved from inside the box", (
    tester,
  ) async {
    await _pump(tester, _case("Pending", "WAITING_APPROVAL"));
    expect(_bar(tester).stage!.index, 4);
    expect(_inTodo(find.text("견적 요청 메일 초안을 확인해 주세요")), findsOneWidget);
    expect(_inTodo(find.widgetWithText(LdsTag, "초안 승인 대기")), findsOneWidget);
    expect(_inTodo(find.widgetWithText(LdsButton, "초안 확인")), findsOneWidget);
  });

  testWidgets("a failure marks its step red and offers 다시 시도", (tester) async {
    await _pump(
      tester,
      _case("Pending", "FAILED", actions: [WorkCaseAction.resume], item: null),
    );
    final stage = _bar(tester).stage!;
    expect(stage.error, isTrue);
    expect(stage.index, 2);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.widgetWithText(TaskStatusLabel, "오류"), findsOneWidget);
    expect(_inTodo(find.widgetWithText(LdsButton, "다시 시도")), findsOneWidget);
  });

  testWidgets("review ready: plans compared, 검토 보류 goes to the next case", (
    tester,
  ) async {
    var next = 0;
    await _pump(
      tester,
      _case("Complete", "REVIEW_READY"),
      onNext: () => next++,
    );
    expect(_bar(tester).stage!.index, 5);
    // 구매안 선택은 사용자 차례(확인 필요)라 '대기'입니다.
    expect(find.widgetWithText(TaskStatusLabel, "대기"), findsOneWidget);
    expect(_inTodo(find.text("구매안을 골라 주세요")), findsOneWidget);
    expect(_inTodo(find.text("구매안 2개")), findsOneWidget);
    expect(_inTodo(find.textContaining("「전량 전환」")), findsOneWidget);
    expect(_inTodo(find.text("5,400,000원")), findsOneWidget);
    expect(_inTodo(find.text("최저 총액")), findsOneWidget);
    expect(_inTodo(find.text("+400,000원")), findsOneWidget);
    expect(_inTodo(find.widgetWithText(LdsButton, "검토 카드 보기")), findsOneWidget);
    await tester.tap(find.widgetWithText(LdsButton, "검토 보류"));
    expect(next, 1);
  });

  group("attachments (SSOT 7.18)", () {
    testWidgets("hidden when the mail has none", (tester) async {
      await _pump(tester, _case("Running", "WAITING_REPLY"));
      expect(find.textContaining("첨부파일"), findsNothing);
      expect(find.byType(AttachmentCard), findsNothing);
    });

    testWidgets("folded at first; a tap unfolds the PDF below, full width", (
      tester,
    ) async {
      await _pump(
        tester,
        _case("Running", "WAITING_REPLY", attachments: 1),
        attachments: [_pdf],
      );
      expect(find.text("첨부파일 1"), findsOneWidget);
      expect(find.text("PDF · 140KB"), findsOneWidget);
      // Nothing opened beside the detail or below it yet.
      expect(find.byType(AttachmentViewer), findsNothing);

      await tester.tap(find.byType(AttachmentCard));
      await tester.pumpAndSettle();
      final viewer = find.byType(AttachmentViewer);
      expect(viewer, findsOneWidget);
      expect(find.text("PDF 페이지"), findsOneWidget);
      expect(find.widgetWithText(LdsButton, "크게 보기"), findsOneWidget);
      // Below the card, as wide as the mail card above it.
      expect(
        tester.getTopLeft(viewer).dy,
        greaterThan(tester.getBottomLeft(find.byType(AttachmentCard)).dy),
      );
      final card = find.ancestor(
        of: find.text("받은 메일 · 근거 자료"),
        matching: find.byType(CaseSectionCard),
      );
      expect(
        tester.getSize(viewer).width,
        closeTo(tester.getSize(card).width - 48 - 2, 1),
      );

      // Folds again with the card or ×.
      await tester.tap(find.byType(AttachmentCard));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentViewer), findsNothing);
      await tester.tap(find.byType(AttachmentCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip("첨부 닫기"));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentViewer), findsNothing);
    });
  });
}
