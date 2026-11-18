import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log_filter.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log_state.dart";
import "package:gyeonjwo_frontend/features/workflow_log/presentation/workflow_log_dialog.dart";
import "package:gyeonjwo_frontend/features/workflow_log/presentation/workflow_log_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/widgets/workspace_shell.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../helpers/platform_override.dart";

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: "buyer@example.invalid",
  );
}

const _entries = [
  WorkflowLogEntry(
    id: "l1",
    createdAt: "2026-10-19T03:12:00Z",
    componentCode: "NODE",
    actorCode: "MAIL_SENDER",
    eventCode: "SEND_RESULT",
    summary: "다온신선푸드 추가 확인 메일 발송 결과를 확인하지 못함",
    outcome: LogOutcome.waiting,
    caseId: "c1",
    caseTitle: "[단가변경] 11월 냉동 딸기 공급단가 조정 안내",
    durationMs: 30000,
    toolName: "gmail.send",
    errorCode: "SEND_TIMEOUT",
  ),
  WorkflowLogEntry(
    id: "l2",
    createdAt: "2026-10-19T03:11:00Z",
    componentCode: "NODE",
    actorCode: "MAIL_SENDER",
    eventCode: "AUTO_SEND",
    summary: "자동 발송 시작",
    outcome: LogOutcome.success,
    caseId: "c1",
    caseTitle: "[단가변경] 11월 냉동 딸기 공급단가 조정 안내",
  ),
];

class _Logs extends WorkflowLogViewModel {
  @override
  Future<WorkflowLogState> build() async => const WorkflowLogState(
    filter: WorkflowLogFilter(),
    entries: _entries,
    total: 2,
    selectedId: "l1",
  );
}

Future<GoRouter> _pump(WidgetTester tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: "/tasks",
    routes: [
      GoRoute(
        path: "/tasks",
        builder: (_, _) => const WorkspaceShell(child: Text("page tasks")),
      ),
      GoRoute(
        path: "/tasks/:caseId",
        builder: (_, state) => WorkspaceShell(
          child: Text("page case ${state.pathParameters["caseId"]}"),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionViewModelProvider.overrideWith(_SignedIn.new),
        workflowLogViewModelProvider.overrideWith(_Logs.new),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _openFromMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip("계정 메뉴"));
  await tester.pumpAndSettle();
  await tester.tap(find.text("처리 이력"));
  await tester.pumpAndSettle();
}

Finder get _card => find
    .descendant(of: find.byType(Dialog), matching: find.byType(Material))
    .first;

void main() {
  testWidgets("the account menu opens the logs as a popup over the page", (
    tester,
  ) async {
    final router = await _pump(tester);
    await _openFromMenu(tester);

    expect(router.state.uri.path, "/tasks");
    expect(find.text("page tasks"), findsOneWidget);
    final dialog = find.byType(WorkflowLogDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text("처리 이력")),
      findsOneWidget,
    );
    // List and detail side by side.
    expect(
      find.descendant(of: dialog, matching: find.text("자동 발송 시작")),
      findsOneWidget,
    );
    expect(find.widgetWithText(LdsButton, "업무 보기"), findsOneWidget);
    final list = tester.getCenter(find.text("자동 발송 시작"));
    final detail = tester.getCenter(find.widgetWithText(LdsButton, "업무 보기"));
    expect(detail.dx, greaterThan(list.dx));
    expect(find.byTooltip("새로고침"), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    expect(find.byType(WorkflowLogDialog), findsNothing);
    expect(router.state.uri.path, "/tasks");
  });

  testWidgets("'업무 보기' closes the popup and opens the case", (tester) async {
    final router = await _pump(tester);
    await _openFromMenu(tester);
    await tester.tap(find.widgetWithText(LdsButton, "업무 보기"));
    await tester.pumpAndSettle();
    expect(find.byType(WorkflowLogDialog), findsNothing);
    expect(router.state.uri.path, "/tasks/c1");
    expect(find.text("page case c1"), findsOneWidget);
  });

  testWidgets("choosing another log keeps the popup in place", (tester) async {
    await _pump(tester);
    await _openFromMenu(tester);
    final rect = tester.getRect(_card);
    await tester.tap(find.text("자동 발송 시작"));
    await tester.pumpAndSettle();
    expect(tester.getRect(_card), rect);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a narrower window stacks the detail under the list", (
    tester,
  ) async {
    await _pump(tester);
    tester.view.physicalSize = const Size(960, 700);
    await tester.pumpAndSettle();
    showWorkflowLogDialog(tester.element(find.text("page tasks")));
    await tester.pumpAndSettle();
    expect(find.byType(WorkflowLogDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("from the 900px-and-narrower menu, the popup takes the keys", (
    tester,
  ) async {
    await _pump(tester);
    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("메뉴 열기"));
    await tester.pumpAndSettle();
    await _openFromMenu(tester);
    expect(find.byType(WorkflowLogDialog), findsOneWidget);
    // Focus is in the popup, so Esc closes it.
    expect(
      ModalRoute.of(FocusManager.instance.primaryFocus!.context!),
      isA<DialogRoute<void>>(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(WorkflowLogDialog), findsNothing);
  });
}
