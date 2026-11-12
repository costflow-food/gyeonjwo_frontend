import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/intake_mail.dart";
import "package:gyeonjwo_frontend/features/mail_intake/presentation/mail_intake_dialog.dart";
import "package:gyeonjwo_frontend/features/mail_intake/presentation/mail_intake_view_model.dart";

IntakeMail _mail(String id) => IntakeMail(
  mailId: id,
  subject: "제목 $id",
  sender: "$id@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  bodyText: "본문 $id",
  reason: IntakeReason.uncertain,
  reasonDetail: "",
  attachments: const [],
  candidates: const [],
  revision: 1,
);

IntakePage _page(List<String> ids) => IntakePage(
  items: [for (final id in ids) _mail(id)],
  totalPending: ids.length,
);

/// Stands in for the 15-second poll: the test replaces the list directly.
class _FakeIntake extends MailIntakeViewModel {
  _FakeIntake(this._first);
  final IntakePage _first;

  @override
  Future<IntakePage> build() async => _first;

  void show(IntakePage page) => state = AsyncData(page);

  /// When set, a resolve stays in flight until the test completes it.
  Completer<void>? pending;

  @override
  Future<void> resolve(
    IntakeMail mail,
    IntakeResolution resolution, {
    String? targetCaseId,
    String? reason,
  }) => pending!.future;
}

void main() {
  Future<_FakeIntake> open(
    WidgetTester tester,
    List<String> ids, {
    String? selected,
    Size size = const Size(1400, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final intake = _FakeIntake(_page(ids));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mailIntakeViewModelProvider.overrideWith(() => intake)],
        child: MaterialApp(
          home: Scaffold(body: MailIntakeDialog(initialMailId: selected)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return intake;
  }

  String reasonText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets("a newer mail arriving does not replace the open mail", (
    tester,
  ) async {
    final intake = await open(tester, ["b", "c"], selected: "b");
    expect(find.text("본문 b"), findsOneWidget);
    await tester.enterText(find.byType(TextField), "규격이 달라 새 업무로");

    intake.show(_page(["n", "b", "c"]));
    await tester.pumpAndSettle();

    expect(find.text("본문 b"), findsOneWidget);
    expect(find.text("본문 n"), findsNothing);
    expect(reasonText(tester), "규격이 달라 새 업무로");
  });

  testWidgets("without a picked mail, the first one stays open", (
    tester,
  ) async {
    final intake = await open(tester, ["b", "c"]);
    expect(find.text("본문 b"), findsOneWidget);

    intake.show(_page(["n", "b", "c"]));
    await tester.pumpAndSettle();

    expect(find.text("본문 b"), findsOneWidget);
    expect(find.text("본문 n"), findsNothing);
  });

  testWidgets("when the open mail leaves the list, its inputs are cleared", (
    tester,
  ) async {
    final intake = await open(tester, ["b", "c"], selected: "b");
    await tester.enterText(find.byType(TextField), "b에 쓴 사유");

    intake.show(_page(["n", "c"]));
    await tester.pumpAndSettle();

    expect(find.text("본문 b"), findsNothing);
    expect(find.text("본문 n"), findsOneWidget);
    expect(reasonText(tester), isEmpty);
  });

  // Narrower than 600: the phone layout, which shows one mail and no list.
  const phone = Size(360, 720);

  testWidgets("phone: when the open mail leaves the list, no other mail "
      "takes its place", (tester) async {
    final intake = await open(tester, ["b", "c"], selected: "b", size: phone);
    expect(find.text("본문 b"), findsOneWidget);

    intake.show(_page(["n", "c"]));
    await tester.pumpAndSettle();

    expect(find.text("본문 n"), findsNothing);
    expect(find.text("이 메일은 이미 처리되어 목록에서 빠졌습니다."), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text("비업무로 확인"),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets("phone: back does not close the screen while a request is "
      "in flight", (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final intake = _FakeIntake(_page(["b", "c"]))..pending = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mailIntakeViewModelProvider.overrideWith(() => intake)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMailIntakeDialog(context, mailId: "b"),
                child: const Text("열기"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("열기"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("비업무로 확인"));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MailIntakeDialog), findsOneWidget);

    intake.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MailIntakeDialog), findsNothing);
    expect(find.text("비업무로 확인했습니다."), findsOneWidget);
  });

  testWidgets("phone: the full-screen dialog fills behind the status bar", (
    tester,
  ) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);
    final intake = _FakeIntake(_page(["b"]));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mailIntakeViewModelProvider.overrideWith(() => intake)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMailIntakeDialog(context, mailId: "b"),
                child: const Text("열기"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("열기"));
    await tester.pumpAndSettle();

    // The dialog surface starts at the very top, so no strip of the screen
    // behind shows (or takes a dismissing tap); the content stays below the
    // status bar.
    final surface = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Material),
    );
    expect(tester.getTopLeft(surface.first).dy, 0);
    expect(tester.getTopLeft(find.text("본문 b")).dy, greaterThan(24));
  });
}
