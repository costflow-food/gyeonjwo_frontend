import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/gmail_connection_view_model.dart";
import "package:gyeonjwo_frontend/features/dashboard/presentation/dashboard_view.dart";
import "package:gyeonjwo_frontend/features/dashboard/presentation/widgets/category_share_card.dart";
import "package:gyeonjwo_frontend/features/dashboard/presentation/widgets/monthly_trend_card.dart";
import "package:gyeonjwo_frontend/features/mail_intake/data/mail_intake_repository_impl.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/intake_mail.dart";
import "package:gyeonjwo_frontend/features/mail_intake/domain/mail_intake_repository.dart";
import "package:gyeonjwo_frontend/features/mail_intake/presentation/mail_intake_dialog.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

class _Visible extends AppVisible {
  @override
  bool build() => true;
}

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(status: AuthSessionStatus.signedIn);
}

WorkCase _case(String id, String status, String step) => WorkCase(
  id: id,
  initialMailId: "m-$id",
  title: "업체 $id",
  sender: "$id@example.invalid",
  receivedAt: "2026-11-10T00:00:00Z",
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: step,
  inputRevision: 1,
  attachmentCount: 0,
);

/// 확인 필요 2 · 진행 중 1 · 완료(보관) 3.
class _Queue implements WorkQueueRepository {
  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
    bool archived = false,
  }) async => archived
      ? const WorkQueuePage(items: [], counts: WorkQueueCounts(total: 3))
      : WorkQueuePage(
          items: [
            _case("c1", "Waiting", "PENDING_START"),
            _case("c2", "Complete", "REVIEW_READY"),
            _case("r1", "Running", "WAITING_REPLY"),
          ],
          counts: const WorkQueueCounts(total: 3),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 접수 대기 4건.
class _Intake implements MailIntakeRepository {
  @override
  Future<IntakePage> getPending({String? cursor}) async =>
      const IntakePage(items: [], totalPending: 4);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<GoRouter> _pump(WidgetTester tester, {double width = 1440}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: "/", builder: (_, _) => const DashboardView()),
      GoRoute(
        path: "/tasks",
        builder: (_, state) => Text("tasks ${state.uri}"),
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
        authSessionViewModelProvider.overrideWith(_SignedIn.new),
        gmailCapabilitiesProvider.overrideWithValue(GmailCapabilities.unknown),
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

Finder _card(String name) => find
    .ancestor(of: find.text(name), matching: find.byType(LdsFocusRing))
    .first;

String _number(WidgetTester tester, String name) => tester
    .widgetList<RichText>(
      find.descendant(of: _card(name), matching: find.byType(RichText)),
    )
    .map((text) => text.text.toPlainText())
    .firstWhere((text) => text.endsWith(" 건"));

void main() {
  testWidgets("four cards and the whole count without 미분류", (tester) async {
    await _pump(tester);
    expect(_number(tester, "확인 필요"), "2 건");
    expect(_number(tester, "진행 중"), "1 건");
    expect(_number(tester, "완료"), "3 건");
    expect(_number(tester, "미분류 메일"), "4 건");
    // 2 + 1 + 3: 미분류 is not a case yet.
    expect(find.text("6 건"), findsOneWidget);
    // Bar 10 tall, parts by count (2 : 1 : 3) with 4 between.
    final widths = [
      for (final code in ["confirm", "running", "complete"])
        tester.getSize(find.byKey(ValueKey("bar-$code"))),
    ];
    for (final size in widths) {
      expect(size.height, 10);
    }
    expect(widths[0].width, closeTo(widths[1].width * 2, 1));
    expect(widths[2].width, closeTo(widths[1].width * 3, 1));
    // No sentences on the cards.
    expect(find.text("보기 ›"), findsNWidgets(3));
    expect(find.text("확인 ›"), findsOneWidget);
  });

  testWidgets("only 확인 필요 is emphasized", (tester) async {
    await _pump(tester);
    Material material(String name) => tester.widget<Material>(
      find.descendant(of: _card(name), matching: find.byType(Material)).first,
    );
    final confirm = material("확인 필요");
    expect(confirm.color, LdsColors.primaryRow);
    final side = (confirm.shape! as RoundedRectangleBorder).side;
    expect(side.color, LdsColors.primary);
    expect(side.width, 1.5);
    expect(
      find.descendant(of: _card("확인 필요"), matching: find.text("지금 할 일")),
      findsOneWidget,
    );
    expect(material("진행 중").color, Colors.white);
    // 미분류 메일: white with a dashed border, not a status color.
    expect(material("미분류 메일").color, Colors.white);
    expect(find.text("지금 할 일"), findsOneWidget);
  });

  testWidgets("a status card opens Tasks on its tab", (tester) async {
    final router = await _pump(tester);
    await tester.tap(_card("진행 중"));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), "/tasks?tab=running");
  });

  testWidgets("미분류 opens the intake dialog", (tester) async {
    await _pump(tester);
    await tester.tap(_card("미분류 메일"));
    await tester.pumpAndSettle();
    expect(find.byType(MailIntakeDialog), findsOneWidget);
  });

  testWidgets("one row when wide, 2×2 under 1100", (tester) async {
    await _pump(tester);
    expect(
      tester.getTopLeft(_card("미분류 메일")).dy,
      tester.getTopLeft(_card("확인 필요")).dy,
    );
    await _pump(tester, width: 1099);
    expect(
      tester.getTopLeft(_card("완료")).dy,
      greaterThan(tester.getBottomLeft(_card("확인 필요")).dy),
    );
    expect(
      tester.getTopLeft(_card("진행 중")).dy,
      tester.getTopLeft(_card("확인 필요")).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("trend and share cards sit side by side when wide", (
    tester,
  ) async {
    await _pump(tester);
    final trend = find.byType(MonthlyTrendCard);
    final share = find.byType(CategoryShareCard);
    expect(tester.getTopLeft(trend).dy, tester.getTopLeft(share).dy);
    // Same height: the share rows fill what the chart leaves.
    expect(tester.getSize(trend).height, tester.getSize(share).height);
    expect(find.text("44,532,400원"), findsOneWidget);
    expect(find.text("직전 기간보다 8% 절감"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a trend item switches the chart", (tester) async {
    await _pump(tester);
    expect(find.text("12월 27건"), findsOneWidget); // 접수 first
    final tab = find.text("견적 요청");
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
    expect(find.text("12월 20건"), findsOneWidget);
    expect(find.text("견적 요청"), findsNWidgets(2)); // tab + legend
  });

  testWidgets("narrow: trend over share, no overflow", (tester) async {
    for (final width in [1099.0, 760.0]) {
      await _pump(tester, width: width);
      expect(
        tester.getTopLeft(find.byType(CategoryShareCard)).dy,
        greaterThan(tester.getBottomLeft(find.byType(MonthlyTrendCard)).dy),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
