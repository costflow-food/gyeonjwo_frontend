import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/account_settings_dialog.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/gmail_connection_view_model.dart";
import "package:gyeonjwo_frontend/features/mail_draft/domain/mail_draft.dart";
import "package:gyeonjwo_frontend/features/send_settings/domain/send_settings.dart";
import "package:gyeonjwo_frontend/features/send_settings/presentation/send_settings_view_model.dart";
import "package:gyeonjwo_frontend/features/server_status/domain/server_status.dart";
import "package:gyeonjwo_frontend/features/server_status/presentation/server_status_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/widgets/workspace_shell.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: "buyer@example.invalid",
  );
}

class _NotConnected extends GmailConnectionViewModel {
  @override
  Future<GmailConnection> build() async => const GmailConnection.notConnected();
}

class _ServerReady extends ServerStatusViewModel {
  @override
  Future<ServerStatus> build() async => const ServerStatus();
}

class _Settings extends SendSettingsViewModel {
  @override
  Future<SendSettings> build(String scope) async => const SendSettings(
    mailboxRef: "mb",
    configured: true,
    settingsVersion: 1,
    approvals: [
      PurposeApproval(
        purpose: DraftPurpose.rfq,
        ownValue: true,
        effectiveValue: true,
      ),
    ],
    missingItems: [],
    tone: MailTone.formal,
    signature: "구매팀 드림",
  );

  @override
  Future<SendSettings> save(SendSettingsUpdate update) async {
    await _saveGate?.future;
    return (await future).copyWithTone(update.tone);
  }
}

/// 저장 요청이 끝나지 않게 붙잡아 둘 때 씁니다.
Completer<void>? _saveGate;

extension on SendSettings {
  SendSettings copyWithTone(MailTone tone) => SendSettings(
    mailboxRef: mailboxRef,
    configured: configured,
    settingsVersion: settingsVersion + 1,
    approvals: approvals,
    missingItems: missingItems,
    tone: tone,
    signature: signature,
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
        path: "/login/permissions",
        builder: (_, state) => Text("permissions from ${state.extra}"),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionViewModelProvider.overrideWith(_SignedIn.new),
        gmailConnectionViewModelProvider.overrideWith(_NotConnected.new),
        serverStatusViewModelProvider.overrideWith(_ServerReady.new),
        sendSettingsViewModelProvider.overrideWith2((_) => _Settings()),
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
  await tester.tap(find.text("계정 설정"));
  await tester.pumpAndSettle();
}

/// 메일 발송 설정 탭에서 문안 어조를 바꿔 저장하지 않은 변경을 만듭니다.
Future<void> _editSendSettings(WidgetTester tester) async {
  await tester.tap(find.text("메일 발송 설정"));
  await tester.pumpAndSettle();
  await tester.tap(find.text("문안·서명"));
  await tester.pumpAndSettle();
  final other = MailTone.values.firstWhere((tone) => tone != MailTone.formal);
  await tester.tap(find.text(other.label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("the account menu opens settings as a popup over the page", (
    tester,
  ) async {
    final router = await _pump(tester);
    await _openFromMenu(tester);

    expect(router.state.uri.path, "/tasks");
    expect(find.text("page tasks"), findsOneWidget);
    final dialog = find.byType(LdsDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text("계정 설정")),
      findsOneWidget,
    );
    for (final text in ["권한", "메일 발송 설정", "Google 연결", "Gmail 읽기"]) {
      expect(
        find.descendant(of: dialog, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    // Inside the popup there is no card frame and no phone-only buttons.
    expect(
      find.descendant(of: dialog, matching: find.byType(LdsPanel)),
      findsNothing,
    );
    expect(find.text("로그아웃"), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsNothing);
    expect(router.state.uri.path, "/tasks");
  });

  testWidgets("both tabs work inside the popup", (tester) async {
    await _pump(tester);
    await _openFromMenu(tester);
    await tester.tap(find.text("메일 발송 설정"));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(LdsButton, "설정 저장"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("reconnecting closes the popup and opens the permissions page", (
    tester,
  ) async {
    final router = await _pump(tester);
    await _openFromMenu(tester);
    await tester.tap(find.text("다시 연결하기"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsNothing);
    expect(router.state.uri.path, "/login/permissions");
    // Phone back from there returns to the page the popup was opened on.
    expect(find.text("permissions from /tasks"), findsOneWidget);
  });

  testWidgets("unsaved send settings: closing asks first", (tester) async {
    await _pump(tester);
    await _openFromMenu(tester);
    await _editSendSettings(tester);

    // Close button: keep editing.
    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    expect(find.text("변경한 설정을 버리시겠습니까?"), findsOneWidget);
    await tester.tap(find.text("계속 설정"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsOneWidget);

    // Esc also asks; discarding closes.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("변경한 설정을 버리시겠습니까?"), findsOneWidget);
    await tester.tap(find.text("변경사항 버리기"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsNothing);
  });

  testWidgets("unsaved send settings: reconnecting asks first", (tester) async {
    final router = await _pump(tester);
    await _openFromMenu(tester);
    await _editSendSettings(tester);
    await tester.tap(find.text("권한"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("다시 연결하기"));
    await tester.pumpAndSettle();
    expect(find.text("변경한 설정을 버리시겠습니까?"), findsOneWidget);
    await tester.tap(find.text("계속 설정"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsOneWidget);
    expect(router.state.uri.path, "/tasks");
  });

  testWidgets("showAccountSettingsDialog opens the same popup", (tester) async {
    await _pump(tester);
    showAccountSettingsDialog(tester.element(find.text("page tasks")));
    await tester.pumpAndSettle();
    expect(find.byType(AccountSettingsDialog), findsOneWidget);
  });

  testWidgets("while saving, the popup does not close", (tester) async {
    _saveGate = Completer<void>();
    addTearDown(() => _saveGate = null);
    await _pump(tester);
    await _openFromMenu(tester);
    await _editSendSettings(tester);
    await tester.tap(find.widgetWithText(LdsButton, "설정 저장"));
    await tester.pump();
    expect(find.widgetWithText(LdsButton, "저장 중"), findsOneWidget);

    await tester.tap(find.byTooltip("닫기"));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text("변경한 설정을 버리시겠습니까?"), findsNothing);
    expect(find.byType(LdsDialog), findsOneWidget);

    _saveGate!.complete();
    await tester.pumpAndSettle();
    // Saved: the notice shows on the popup, not behind the blur.
    expect(
      find.descendant(
        of: find.byType(AccountSettingsDialog),
        matching: find.text("발송 설정을 저장했습니다."),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip("닫기"));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsNothing);
  });

  testWidgets("Esc right after an edit still asks first", (tester) async {
    await _pump(tester);
    await _openFromMenu(tester);
    await tester.tap(find.text("메일 발송 설정"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("문안·서명"));
    await tester.pumpAndSettle();
    final other = MailTone.values.firstWhere((tone) => tone != MailTone.formal);
    await tester.tap(find.text(other.label));
    // No frame in between.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("변경한 설정을 버리시겠습니까?"), findsOneWidget);
    expect(find.byType(LdsDialog), findsOneWidget);
  });

  testWidgets("switching tabs keeps the popup and its tabs in place", (
    tester,
  ) async {
    await _pump(tester);
    await _openFromMenu(tester);
    final card = find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first;
    final rect = tester.getRect(card);
    final tabs = tester.getTopLeft(find.text("권한"));
    await tester.tap(find.text("메일 발송 설정"));
    await tester.pumpAndSettle();
    expect(tester.getRect(card), rect);
    expect(tester.getTopLeft(find.text("권한")), tabs);
  });

  testWidgets("a click outside closes the popup when nothing is unsaved", (
    tester,
  ) async {
    await _pump(tester);
    await _openFromMenu(tester);
    await tester.tapAt(const Offset(1400, 40));
    await tester.pumpAndSettle();
    expect(find.byType(LdsDialog), findsNothing);
  });

  testWidgets("from the 900px-and-narrower menu, the popup takes the keys", (
    tester,
  ) async {
    final router = await _pump(tester);
    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("메뉴 열기"));
    await tester.pumpAndSettle();
    await _openFromMenu(tester);
    expect(find.byType(AccountSettingsDialog), findsOneWidget);
    expect(
      ModalRoute.of(FocusManager.instance.primaryFocus!.context!),
      isA<DialogRoute<void>>(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AccountSettingsDialog), findsNothing);
    expect(router.state.uri.path, "/tasks");
  });
}
