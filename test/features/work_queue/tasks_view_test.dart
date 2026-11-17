import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/gmail_connection_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_case_change_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/task_row.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart";
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

WorkCase _case(String id, String status, String step, {String? item}) =>
    WorkCase(
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
      itemName: item ?? "냉동 딸기",
    );

/// Two cases for the user (확인 필요), one waiting on a supplier (진행 중),
/// and a long item group to scroll.
class _Queue implements WorkQueueRepository {
  _Queue({this.longGroup = false});

  final bool longGroup;

  @override
  Future<WorkQueuePage> getCases({
    WorkCaseStatus? status,
    String query = "",
    String? cursor,
    int? limit,
    bool archived = false,
  }) async {
    if (archived) {
      return const WorkQueuePage(items: [], counts: WorkQueueCounts());
    }
    final items = [
      _case("c1", "Waiting", "PENDING_START"),
      _case("c2", "Pending", "FAILED"),
      _case("r1", "Running", "WAITING_REPLY", item: "깐마늘"),
      if (longGroup)
        for (var i = 0; i < 30; i++)
          _case("l$i", "Running", "WAITING_REPLY", item: "제주감귤"),
    ];
    return WorkQueuePage(
      items: items,
      counts: WorkQueueCounts(total: items.length),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  String at = "/tasks",
  double width = 1440,
  bool longGroup = false,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  TaskGroup? tab(GoRouterState state) =>
      TaskGroup.fromCode(state.uri.queryParameters["tab"]);
  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(
        path: "/tasks",
        builder: (_, state) => WorkQueueView(tab: tab(state)),
      ),
      // A stand-in for the case page: these tests are about the list.
      GoRoute(
        path: "/tasks/:caseId",
        builder: (_, state) => Text("case ${state.uri}"),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workQueueRepositoryProvider.overrideWithValue(
          _Queue(longGroup: longGroup),
        ),
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

LdsBadgeTone _badge(WidgetTester tester, String tab) => tester
    .widget<LdsBadge>(
      find.descendant(
        of: find.ancestor(of: find.text(tab), matching: find.byType(Row)).first,
        matching: find.byType(LdsBadge),
      ),
    )
    .tone;

Iterable<String> _rows(WidgetTester tester) => tester
    .widgetList<TaskRow>(find.byType(TaskRow))
    .map((row) => row.workCase.id);

void main() {
  testWidgets("four tabs with counts; 확인 필요 orange until chosen", (
    tester,
  ) async {
    final router = await _pump(tester);
    expect(_badge(tester, "전체"), LdsBadgeTone.dark);
    expect(_badge(tester, "확인 필요"), LdsBadgeTone.primary);
    expect(_badge(tester, "진행 중"), LdsBadgeTone.neutral);
    expect(_badge(tester, "완료"), LdsBadgeTone.neutral);
    expect(find.text("대기"), findsOneWidget, reason: "row label");
    expect(_rows(tester), unorderedEquals(["c1", "c2", "r1"]));

    // The tab is in the address.
    await tester.tap(find.text("확인 필요"));
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters["tab"], "confirm");
    expect(_badge(tester, "확인 필요"), LdsBadgeTone.dark);
    expect(_badge(tester, "전체"), LdsBadgeTone.neutral);
    expect(_rows(tester), unorderedEquals(["c1", "c2"]));

    await tester.tap(find.text("진행 중").first);
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters["tab"], "running");
    expect(_rows(tester), ["r1"]);
  });

  testWidgets("an address with ?tab opens on that tab", (tester) async {
    await _pump(tester, at: "/tasks?tab=running");
    expect(_badge(tester, "진행 중"), LdsBadgeTone.dark);
    expect(_rows(tester), ["r1"]);
  });

  testWidgets("opening a case keeps the tab", (tester) async {
    final router = await _pump(tester, at: "/tasks?tab=confirm");
    await tester.tap(find.text("업체 c1"));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), "/tasks/c1?tab=confirm");
  });

  testWidgets("groups are boxes with a name and a plain count", (tester) async {
    await _pump(tester);
    expect(find.text("냉동 딸기"), findsOneWidget);
    expect(find.text("2"), findsWidgets);
    await tester.tap(find.text("냉동 딸기"));
    await tester.pumpAndSettle();
    expect(_rows(tester), ["r1"]);
  });

  testWidgets("a group's header stays on top while its rows scroll", (
    tester,
  ) async {
    await _pump(tester, longGroup: true);
    final list = find.byType(CustomScrollView);
    final top = tester.getTopLeft(list).dy;
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text("제주감귤")).dy - top, lessThan(40));
    expect(find.text("제주감귤").hitTestable(), findsOneWidget);
  });

  testWidgets("wide: list 30% (400–480) beside an empty detail", (
    tester,
  ) async {
    await _pump(tester, width: 1440);
    expect(find.text("왼쪽 목록에서 업무를 고르면 내용이 여기에 보입니다."), findsOneWidget);
    expect(
      tester.getSize(find.byType(LdsTabBar<TaskGroup?>)).width,
      WorkQueueView.listWidth(1440),
    );
    expect(WorkQueueView.listWidth(1000), 400);
    expect(WorkQueueView.listWidth(2000), 480);
    // Tasks starts with the icon menu.
    expect(tester.getSize(find.byType(AppSidebar)).width, AppSidebar.iconWidth);
  });

  testWidgets("1100 and narrower: the list alone", (tester) async {
    await _pump(tester, width: 1100);
    expect(find.byType(TaskRow), findsWidgets);
    expect(find.text("왼쪽 목록에서 업무를 고르면 내용이 여기에 보입니다."), findsNothing);
  });
}
