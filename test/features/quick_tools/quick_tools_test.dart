import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:gyeonjwo_frontend/app/app_paths.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_session.dart";
import "package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart";
import "package:gyeonjwo_frontend/features/quick_tools/presentation/calculator_button.dart";
import "package:gyeonjwo_frontend/features/quick_tools/presentation/memo_button.dart";
import "package:gyeonjwo_frontend/features/transactions/presentation/transactions_view.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/preferences.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";
import "package:shared_preferences/shared_preferences.dart";

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: "buyer@example.invalid",
  );
}

/// Invoices 화면(상단 바 포함)을 띄웁니다. [preferences]는 브라우저 저장소.
Future<void> _pump(
  WidgetTester tester, {
  double width = 1440,
  SharedPreferences? preferences,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppPaths.transactions,
    routes: [
      GoRoute(
        path: AppPaths.transactions,
        builder: (context, state) => const TransactionsView(),
      ),
      for (final path in ["/", "/tasks", "/suppliers", "/logs", "/account"])
        GoRoute(path: path, builder: (_, _) => Text("page $path")),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionViewModelProvider.overrideWith(_SignedIn.new),
        if (preferences != null)
          sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(WorkspacePalette.lds),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapKeys(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await tester.tap(
      find.descendant(
        of: find.byType(CalculatorPanel),
        matching: find.bySemanticsLabel(label),
      ),
    );
    await tester.pump();
  }
}

final _memoKey = QuickMemo.keyFor("buyer@example.invalid");

String _display(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(CalculatorPanel.displayKey)).data!;

void main() {
  testWidgets("상단 바 순서: 달력 → 계산기 → 메모 → 검색 → 알림", (tester) async {
    await _pump(tester);
    final xs = [
      for (final tip in ["계산기", "메모", "업무 검색", "알림"])
        tester.getTopLeft(find.byTooltip(tip)).dx,
    ];
    expect(xs, [...xs]..sort());
    expect(
      tester.getTopLeft(find.byType(LdsDateViewButton)).dx,
      lessThan(xs.first),
    );
    // 같은 줄, 같은 크기.
    final ys = {
      for (final tip in ["계산기", "메모", "업무 검색"])
        tester.getTopLeft(find.byTooltip(tip)).dy,
    };
    expect(ys, hasLength(1));
    expect(
      tester.getSize(find.byType(CalculatorButton)),
      tester.getSize(find.byType(MemoButton)),
    );
  });

  testWidgets("좁은 폭(메뉴 단추가 있는 상단 바)에서도 넘치지 않습니다", (tester) async {
    await _pump(tester, width: 620);
    expect(find.byTooltip("계산기"), findsOneWidget);
    expect(find.byTooltip("메모"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("높이가 모자라도 계산기·메모 창이 넘치지 않습니다", (tester) async {
    for (final panel in const <Widget>[CalculatorPanel(), MemoPanel()]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authSessionViewModelProvider.overrideWith(_SignedIn.new)],
          child: MaterialApp(
            theme: buildAppTheme(WorkspacePalette.lds),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(height: 240, child: panel),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: "$panel");
    }
  });

  testWidgets("계산기: 한글 입력 상태의 C·X 글쇠, Ctrl+C 복사", (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip("계산기"));
    await tester.pumpAndSettle();
    await _tapKeys(tester, ["6"]);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: "ㅌ");
    await _tapKeys(tester, ["7", "계산"]);
    expect(_display(tester), "42");
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: "ㅊ");
    await tester.pump();
    expect(_display(tester), "0");
  });

  testWidgets("계산기: 단추로 계산하고, 닫았다 열어도 값이 남습니다", (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip("계산기"));
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorPanel), findsOneWidget);
    expect(_display(tester), "0");

    await _tapKeys(tester, ["1", "2", "0", "0", "곱하기", "3", "계산"]);
    expect(_display(tester), "3,600");
    expect(find.text("1,200 × 3 ="), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorPanel), findsNothing);

    await tester.tap(find.byTooltip("계산기"));
    await tester.pumpAndSettle();
    expect(_display(tester), "3,600");

    await _tapKeys(tester, ["모두 지우기"]);
    expect(_display(tester), "0");
  });

  testWidgets("계산기: 자판으로 적고 Enter로 계산, 결과를 복사합니다", (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "Clipboard.setData") {
          copied = (call.arguments as Map)["text"] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester);
    await tester.tap(find.byTooltip("계산기"));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit7, character: "7");
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd, character: "+");
    await tester.sendKeyEvent(LogicalKeyboardKey.digit8, character: "8");
    await tester.sendKeyEvent(
      LogicalKeyboardKey.numpadMultiply,
      character: "*",
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2, character: "2");
    await tester.pump();
    expect(find.text("7 + 8 ×"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_display(tester), "23");

    await tester.tap(find.text("결과 복사"));
    await tester.pump();
    expect(copied, "23");
    expect(find.text("복사했어요"), findsOneWidget);

    // 0으로 나누면 안내를 보여 주고 복사는 막습니다.
    await _tapKeys(tester, ["나누기", "0", "계산"]);
    expect(_display(tester), "0으로 나눌 수 없어요");
    await tester.tap(find.text("결과 복사"));
    await tester.pump();
    expect(copied, "23");
  });

  testWidgets("계산 이력: '='마다 남기고, 누르면 결과를 가져옵니다", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final key = CalculatorHistory.keyFor("buyer@example.invalid");
    await _pump(tester, preferences: preferences);
    await tester.tap(find.byTooltip("계산기"));
    await tester.pumpAndSettle();

    // 처음엔 비어 있습니다.
    await tester.tap(find.text("이력"));
    await tester.pump();
    expect(find.text("아직 계산 이력이 없어요"), findsOneWidget);
    await tester.tap(find.text("숫자판"));
    await tester.pump();

    await _tapKeys(tester, ["1", "2", "0", "0", "곱하기", "3", "계산"]);
    // '='을 다시 눌러도, 0으로 나눠도 이력은 늘지 않습니다.
    await _tapKeys(tester, ["계산", "모두 지우기", "5", "나누기", "0", "계산"]);
    await _tapKeys(tester, ["모두 지우기", "2", "더하기", "3", "계산"]);
    expect(preferences.getStringList(key), hasLength(2));
    await _tapKeys(tester, ["모두 지우기"]);

    await tester.tap(find.text("이력"));
    await tester.pump();
    // 최근 것이 위.
    final first = find.bySemanticsLabel("2 + 3 = 5, 결과 가져오기");
    final second = find.bySemanticsLabel("1,200 × 3 = 3,600, 결과 가져오기");
    expect(first, findsOneWidget);
    expect(tester.getTopLeft(first).dy, lessThan(tester.getTopLeft(second).dy));

    // 줄을 누르면 그 결과를 넣고 숫자판으로 돌아옵니다.
    await tester.tap(second);
    await tester.pump();
    expect(_display(tester), "3,600");
    expect(find.text("이력"), findsOneWidget);
    await _tapKeys(tester, ["더하기", "1", "계산"]);
    expect(_display(tester), "3,601");
    expect(preferences.getStringList(key), hasLength(3));

    // 지우면 저장소에서도 지웁니다.
    await tester.tap(find.text("이력"));
    await tester.pump();
    await tester.tap(find.text("이력 지우기"));
    await tester.pump();
    expect(find.text("아직 계산 이력이 없어요"), findsOneWidget);
    expect(preferences.getStringList(key), isNull);
  });

  testWidgets("계산 이력: 저장소에 있던 이력을 보여 주고, 깨진 줄은 건너뜁니다", (tester) async {
    SharedPreferences.setMockInitialValues({
      CalculatorHistory.keyFor("buyer@example.invalid"): [
        '{"e":"10 ÷ 4 =","r":"2.5"}',
        "깨진 줄",
        '{"e":"1 + 1 =","r":"2"}',
      ],
      CalculatorHistory.keyFor("other@example.invalid"): [
        '{"e":"9 × 9 =","r":"81"}',
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    await _pump(tester, preferences: preferences);
    await tester.tap(find.byTooltip("계산기"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("이력"));
    await tester.pump();
    expect(find.text("10 ÷ 4 ="), findsOneWidget);
    expect(find.text("2.5"), findsOneWidget);
    expect(find.text("1 + 1 ="), findsOneWidget);
    // 다른 계정의 이력은 보이지 않습니다.
    expect(find.text("9 × 9 ="), findsNothing);
  });

  testWidgets("메모: 적는 대로 저장하고, 다시 열면 그대로 보입니다", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await _pump(tester, preferences: preferences);
    expect(find.byTooltip("메모"), findsOneWidget);

    await tester.tap(find.byTooltip("메모"));
    await tester.pumpAndSettle();
    expect(find.text(MemoPanel.hint), findsOneWidget);
    expect(find.text(MemoPanel.note), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(MemoPanel),
        matching: find.byType(TextField),
      ),
      "한라푸드 단가 재확인\n목요일 전화",
    );
    await tester.pump();
    expect(preferences.getString(_memoKey), "한라푸드 단가 재확인\n목요일 전화");
    expect(find.text("18/5000"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MemoPanel), findsNothing);
    // 적어 둔 메모가 있으면 단추 이름이 바뀝니다.
    expect(find.byTooltip("메모, 적어 둔 메모 있음"), findsOneWidget);

    await tester.tap(find.byTooltip("메모, 적어 둔 메모 있음"));
    await tester.pumpAndSettle();
    expect(find.text("한라푸드 단가 재확인\n목요일 전화"), findsOneWidget);

    // 모두 지우면 저장소에서도 지웁니다.
    await tester.enterText(
      find.descendant(
        of: find.byType(MemoPanel),
        matching: find.byType(TextField),
      ),
      "",
    );
    await tester.pump();
    expect(preferences.getString(_memoKey), isNull);
  });

  testWidgets("메모는 계정별로 따로 저장합니다", (tester) async {
    SharedPreferences.setMockInitialValues({
      QuickMemo.keyFor("other@example.invalid"): "다른 계정 메모",
    });
    final preferences = await SharedPreferences.getInstance();
    await _pump(tester, preferences: preferences);
    // 다른 계정의 메모는 보이지 않습니다.
    await tester.tap(find.byTooltip("메모"));
    await tester.pumpAndSettle();
    expect(find.text("다른 계정 메모"), findsNothing);
    expect(find.text(MemoPanel.hint), findsOneWidget);
  });

  testWidgets("메모: 저장소에 있던 메모를 처음부터 보여 줍니다", (tester) async {
    SharedPreferences.setMockInitialValues({_memoKey: "어제 적은 메모"});
    final preferences = await SharedPreferences.getInstance();
    await _pump(tester, preferences: preferences);
    await tester.tap(find.byTooltip("메모, 적어 둔 메모 있음"));
    await tester.pumpAndSettle();
    expect(find.text("어제 적은 메모"), findsOneWidget);
  });
}
