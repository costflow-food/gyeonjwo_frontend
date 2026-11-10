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
}

void main() {
  Future<_FakeIntake> open(
    WidgetTester tester,
    List<String> ids, {
    String? selected,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
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
}
