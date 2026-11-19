import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/domain/gmail_connection.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/gmail_connection_view_model.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/task_group.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_queue_repository.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/widgets/task_row.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view.dart";
import "package:gyeonjwo_frontend/features/work_queue/presentation/work_queue_view_model.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/app_visibility.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

class _Visible extends AppVisible {
  @override
  bool build() => true;
}

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(status: AuthSessionStatus.signedIn);
}

WorkCase _case(
  String id,
  String status,
  String step, {
  String? item,
  String receivedAt = "2026-11-10T00:00:00Z",
  bool archived = false,
}) => WorkCase(
  id: id,
  initialMailId: "m-$id",
  title: "업체 $id",
  sender: "$id@example.invalid",
  receivedAt: receivedAt,
  archived: archived,
  status: WorkCaseStatus.fromCode(status),
  statusCode: status,
  processingStep: step,
  stepMessage: step,
  inputRevision: 1,
  attachmentCount: 0,
  itemName: item ?? "냉동 딸기",
);

/// Two cases for the user (확인 필요), one waiting on a supplier (진행 중),
/// one confirmed (완료, archived), and a long item group to scroll.
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
      return WorkQueuePage(
        items: [
          _case("d1", "Complete", "REVIEW_READY", item: "피망", archived: true),
        ],
        counts: const WorkQueueCounts(total: 1),
      );
    }
    final items = [
      _case(
        "c1",
        "Waiting",
        "PENDING_START",
        receivedAt: "2026-11-11T00:00:00Z",
      ),
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
  Future<OriginalMail> getOriginalMail(String mailId) async => OriginalMail(
    id: mailId,
    subject: "[단가변경] $mailId 단가 조정",
    sender: "영업담당 <$mailId@example.invalid>",
    recipients: const ["buyer@example.invalid"],
    receivedAt: "2026-11-10T00:00:00Z",
    bodyText: "본문",
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  String at = "/tasks",
  double width = 1100,
  bool longGroup = false,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
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
      GoRoute(
        path: "/tasks/:caseId",
        builder: (_, state) => WorkQueueView(
          caseId: state.pathParameters["caseId"],
          tab: tab(state),
        ),
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
  testWidgets("four tabs use neutral counts unless selected", (tester) async {
    final router = await _pump(tester);
    final bar = find.byType(LdsTabBar<TaskGroup?>);
    final tabs = find.descendant(of: bar, matching: find.byType(InkWell));
    expect(tabs, findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      expect(
        tester.getSize(tabs.at(index)).width,
        closeTo(tester.getSize(bar).width / 4, .01),
      );
    }
    expect(_badge(tester, "전체"), LdsBadgeTone.dark);
    expect(_badge(tester, "확인 필요"), LdsBadgeTone.neutral);
    expect(_badge(tester, "진행 중"), LdsBadgeTone.neutral);
    expect(_badge(tester, "완료"), LdsBadgeTone.neutral);
    // Row labels (결정 b): only the case not started yet waits.
    expect(find.text("대기"), findsOneWidget, reason: "row label");
    expect(_rows(tester), unorderedEquals(["c1", "c2", "r1", "d1"]));

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
    expect(_badge(tester, "확인 필요"), LdsBadgeTone.neutral);
    expect(_rows(tester), ["r1"]);

    await tester.tap(find.text("완료").first);
    await tester.pumpAndSettle();
    expect(_rows(tester), ["d1"]);
  });

  testWidgets("전체 counts and shows the confirmed cases too", (tester) async {
    await _pump(tester);
    final all = find.descendant(
      of: find.ancestor(of: find.text("전체"), matching: find.byType(Row)).first,
      matching: find.byType(LdsBadge),
    );
    // 3 open + 1 confirmed (archived).
    expect(tester.widget<LdsBadge>(all).count, 4);
    expect(_rows(tester), contains("d1"));
    expect(find.text("완료"), findsNWidgets(2), reason: "tab and row label");
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

  testWidgets("groups in 가나다 order with a count, no waiting badge", (
    tester,
  ) async {
    await _pump(tester);
    double top(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(top("깐마늘"), lessThan(top("냉동 딸기")));
    expect(top("냉동 딸기"), lessThan(top("피망")));
    // 냉동 딸기: 2 cases, one not started yet.
    final header = find.ancestor(
      of: find.text("냉동 딸기"),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: header.first, matching: find.text("2")),
      findsOneWidget,
    );
    // 접수 대기 수(예전 주황 원 '1')는 보이지 않습니다.
    expect(
      find.descendant(of: header.first, matching: find.text("1")),
      findsNothing,
    );

    // Folding: the chevron turns -90°.
    await tester.tap(find.text("냉동 딸기"));
    await tester.pumpAndSettle();
    expect(_rows(tester), unorderedEquals(["r1", "d1"]));
    final turn = tester.widget<AnimatedRotation>(
      find.descendant(
        of: header.first,
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(turn.turns, -.25);
  });

  testWidgets("search: 제목·보낸 사람, #333D4B 1px when focused", (tester) async {
    await _pump(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.hintText, "제목·보낸 사람 검색");
    final focused = field.decoration!.focusedBorder! as OutlineInputBorder;
    expect(focused.borderSide.color, LdsColors.title);
    expect(focused.borderSide.width, 1);
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

  testWidgets("wide: list 30% beside the first row, opened on its own", (
    tester,
  ) async {
    final router = await _pump(tester, width: 1440);
    // The first visible row (깐마늘 group) is selected, in the address too.
    expect(router.state.uri.toString(), "/tasks/r1");
    expect(find.text("거래처 회신을 모으고 있어요"), findsOneWidget);
    expect(find.text("왼쪽 목록에서 업무를 고르면 내용이 여기에 보입니다."), findsNothing);
    expect(
      tester.getSize(find.byType(LdsTabBar<TaskGroup?>)).width,
      WorkQueueView.listWidth(1440) - 33,
    );
    expect(WorkQueueView.listWidth(1000), 400);
    expect(WorkQueueView.listWidth(2000), 400);
    // All screens share the expanded initial sidebar state.
    expect(tester.getSize(find.byType(AppSidebar)).width, AppSidebar.wideWidth);
    // The list pane is #F3F4F6 with a line on its right; the detail #F9FAFB.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == LdsColors.lineSoft &&
            (widget.decoration! as BoxDecoration).border ==
                const Border(right: BorderSide(color: LdsColors.line)),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == LdsColors.canvas,
      ),
      findsWidgets,
    );
  });

  testWidgets("↑/↓ in the list opens the next and previous rows", (
    tester,
  ) async {
    final router = await _pump(tester, width: 1440, at: "/tasks/r1");
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    tester
        .widget<Focus>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Focus && widget.focusNode?.debugLabel == "업무 목록",
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await press(LogicalKeyboardKey.arrowDown);
    expect(router.state.uri.toString(), "/tasks/c1");
    // The new list keeps the focus.
    await press(LogicalKeyboardKey.arrowUp);
    expect(router.state.uri.toString(), "/tasks/r1");
    // Nothing above the first row.
    await press(LogicalKeyboardKey.arrowUp);
    expect(router.state.uri.toString(), "/tasks/r1");
  });

  testWidgets("1100 and narrower: the list alone, nothing auto-opened", (
    tester,
  ) async {
    final router = await _pump(tester, width: 1100);
    expect(find.byType(TaskRow), findsWidgets);
    expect(router.state.uri.toString(), "/tasks");
    expect(find.text("왼쪽 목록에서 업무를 고르면 내용이 여기에 보입니다."), findsNothing);
  });
}
