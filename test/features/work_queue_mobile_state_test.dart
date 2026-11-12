import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/gmail_connection_view_model.dart";
import "package:gyeonjwo_frontend/features/mail_intake/data/mail_intake_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/intake_mail.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/mail_intake_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/mobile/mobile_work_queue_home.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/queue_group_list.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/work_case_panel.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

class _Visible extends AppVisible {
  @override
  bool build() => true;
}

WorkCase _case(String id, {String? itemName}) => WorkCase(
  id: id,
  initialMailId: "mail-$id",
  title: "제목 $id",
  sender: "$id@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  status: WorkCaseStatus.fromCode("Waiting"),
  statusCode: "Waiting",
  processingStep: "A",
  stepMessage: "",
  inputRevision: 1,
  attachmentCount: 0,
  itemName: itemName,
);

/// Two item groups, long enough to scroll; one mail with an Excel attachment.
class _Queue implements WorkQueueRepository {
  int contentReads = 0;
  final content = Completer<Uint8List>();

  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
  }) async => WorkQueuePage(
    items: [
      for (var i = 0; i < 20; i++) _case("a$i", itemName: "깐양파"),
      for (var i = 0; i < 20; i++) _case("b$i", itemName: "대파"),
    ],
    counts: const WorkQueueCounts(waiting: 40, total: 40),
  );

  @override
  Future<OriginalMail> getOriginalMail(String mailId) async => OriginalMail(
    id: mailId,
    subject: "[단가 인상 안내] 깐양파 10kg 11월 공급가 조정",
    sender: "kim@example.invalid",
    recipients: const ["buyer@example.invalid"],
    receivedAt: "2026-11-11T00:12:00Z",
    bodyText: "안녕하세요.",
    attachments: const [
      MailAttachment(
        id: "att-1",
        filename: "단가표.xlsx",
        mimeType: "application/vnd.ms-excel",
        sizeBytes: 2048,
      ),
    ],
  );

  @override
  Future<Uint8List> getAttachmentContent(String mailId, String attachmentId) {
    contentReads++;
    return content.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Intake implements MailIntakeRepository {
  @override
  Future<IntakePage> getPending({String? cursor}) async =>
      const IntakePage(items: [], totalPending: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("the phone queue keeps its place across a visit to a case", (
    tester,
  ) async {
    _phone(tester);
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (_, _) => const MobileWorkQueueHome()),
        GoRoute(
          path: "/cases/:caseId",
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.go("/"),
              child: const Text("back"),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workQueueRepositoryProvider.overrideWithValue(_Queue()),
          mailIntakeRepositoryProvider.overrideWithValue(_Intake()),
          workCaseChangesProvider.overrideWith((ref) => const Stream.empty()),
          appVisibleProvider.overrideWith(_Visible.new),
          gmailCapabilitiesProvider.overrideWithValue(
            GmailCapabilities.unknown,
          ),
        ],
        child: MaterialApp.router(
          theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fold the first group, then scroll down and open a case.
    await tester.tap(find.text("깐양파 품목"));
    await tester.pumpAndSettle();
    expect(find.text("제목 a0"), findsNothing);
    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    final offset = tester.widget<ListView>(list).controller!.offset;
    expect(offset, greaterThan(0));
    await tester.tap(find.textContaining("제목 b").hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byType(MobileWorkQueueHome), findsNothing);

    await tester.tap(find.text("back"));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListView>(find.byType(ListView).first).controller!.offset,
      offset,
    );
    expect(find.text("제목 a0"), findsNothing);

    // The chosen list survives too.
    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text("접수 확인"));
    await tester.pumpAndSettle();
    expect(find.byType(QueueGroupList), findsNothing);
    router.go("/cases/a1");
    await tester.pumpAndSettle();
    await tester.tap(find.text("back"));
    await tester.pumpAndSettle();
    expect(find.byType(QueueGroupList), findsNothing);

    // Stops the view models' polling timers.
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets("mail labels stay on one line and a download runs once", (
    tester,
  ) async {
    _phone(tester);
    final queue = _Queue();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [workQueueRepositoryProvider.overrideWithValue(queue)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: WorkCasePanel(workCase: _case("c1", itemName: "깐양파")),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // One line each at the larger system font.
    final label = tester.getSize(find.text("보낸 사람"));
    expect(label.height, lessThan(14 * 1.3 * 2));
    expect(
      tester.getRect(find.text("보낸 사람")).right,
      lessThanOrEqualTo(tester.getRect(find.text("kim@example.invalid")).left),
    );

    await tester.ensureVisible(find.text("단가표.xlsx"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("단가표.xlsx"));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text("단가표.xlsx"));
    await tester.pump();
    expect(queue.contentReads, 1);

    // Once it ends (here: no save dialog in tests) the tile is tappable again.
    queue.content.completeError(const WorkQueueFailure("X", "내려받지 못했습니다."));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
