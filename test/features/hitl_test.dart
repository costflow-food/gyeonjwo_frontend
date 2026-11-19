import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:go_router/go_router.dart';
import 'package:gyeonjwo_frontend/features/auth/domain/auth_session.dart';
import 'package:gyeonjwo_frontend/features/auth/presentation/auth_session_view_model.dart';
import 'package:gyeonjwo_frontend/features/hitl/domain/hitl_request.dart';
import 'package:gyeonjwo_frontend/features/hitl/presentation/hitl_view.dart';
import 'package:gyeonjwo_frontend/features/hitl/presentation/hitl_view_model.dart';
import 'package:gyeonjwo_frontend/shared/widgets/lds/lds.dart';
import 'package:gyeonjwo_frontend/shared/widgets/app_sidebar.dart';

import '../helpers/platform_override.dart';

class _SignedIn extends AuthSessionViewModel {
  @override
  AuthSession build() => const AuthSession(
    status: AuthSessionStatus.signedIn,
    email: 'preview@example.invalid',
  );
}

Future<GoRouter> pumpHitl(
  WidgetTester tester, {
  double width = 1440,
  String location = '/hitl',
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/hitl',
        builder: (_, state) =>
            HitlView(requestId: state.uri.queryParameters['request']),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authSessionViewModelProvider.overrideWith(_SignedIn.new)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  test(
    'decisions require a reason and cannot approve a completed request twice',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vm = container.read(hitlViewModelProvider.notifier);
      expect(vm.decide('HITL-DEMO-001', HitlStatus.held, '', '12월'), isFalse);
      expect(vm.decide('missing', HitlStatus.approved, '', 'value'), isFalse);
      expect(
        vm.decide('HITL-DEMO-001', HitlStatus.held, '거래처 확인 대기', '12월'),
        isTrue,
      );
      expect(
        container.read(hitlViewModelProvider).first.status,
        HitlStatus.held,
      );
      expect(
        vm.decide('HITL-DEMO-001', HitlStatus.approved, '확인 완료', '12월 5일'),
        isTrue,
      );
      expect(
        vm.decide('HITL-DEMO-001', HitlStatus.approved, '', '12월 1일'),
        isFalse,
      );
      final request = container.read(hitlViewModelProvider).first;
      expect(request.value, '12월 5일');
      expect(request.history.length, 3);
      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      expect(
        fresh.read(hitlViewModelProvider).first.status,
        HitlStatus.waiting,
      );
    },
  );

  testWidgets(
    'menu follows Tasks; list, source and decision confirmation work',
    (tester) async {
      await pumpHitl(tester);
      expect(AppMenu.values.map((m) => m.label).toList(), [
        'Dashboard',
        'Tasks',
        'HITL',
        'Invoices',
        'Suppliers',
      ]);
      expect(find.text('담당자 검토 요청'), findsOneWidget);
      expect(find.text('왜 확인이 필요한가요?'), findsOneWidget);
      await tester.tap(find.text('시연 원문 보기'));
      await tester.pumpAndSettle();
      expect(find.text('원문·근거 보기'), findsOneWidget);
      Navigator.of(tester.element(find.byType(LdsDialog))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(LdsButton, '승인'));
      await tester.tap(find.widgetWithText(LdsButton, '승인'));
      await tester.pumpAndSettle();
      expect(find.text('승인 완료 처리할까요?'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('승인 완료 처리할까요?'), findsNothing);
      await tester.tap(find.widgetWithText(LdsButton, '승인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('승인 완료 기록'));
      await tester.pumpAndSettle();
      expect(find.text('승인 완료 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search has an empty state and a narrow screen opens and returns from detail',
    (tester) async {
      final router = await pumpHitl(tester, width: 390);
      await tester.enterText(find.byType(TextField), 'not-a-supplier');
      await tester.pumpAndSettle();
      expect(find.text('조건에 맞는 검토 요청이 없습니다.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('공급단가 적용일을 확인해 주세요'));
      await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters['request'], 'HITL-DEMO-001');
      expect(find.text('요청 목록으로'), findsOneWidget);
      await tester.tap(find.text('요청 목록으로'));
      await tester.pumpAndSettle();
      expect(find.text('공급단가 적용일을 확인해 주세요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unknown request never displays another request', (tester) async {
    await pumpHitl(tester, location: '/hitl?request=missing');
    expect(find.text('요청을 찾을 수 없습니다. 목록에서 다시 선택해 주세요.'), findsOneWidget);
    expect(find.text('왜 확인이 필요한가요?'), findsNothing);
  });
}
