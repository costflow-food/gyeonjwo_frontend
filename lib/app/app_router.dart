import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_route_policy.dart';
import '../features/auth/domain/gmail_connection.dart';
import '../features/auth/presentation/auth_session_view_model.dart';
import '../features/auth/presentation/gmail_connection_view_model.dart';
import '../features/auth/presentation/login_view.dart';
import '../features/auth/presentation/account_view.dart';
import '../features/auth/presentation/auth_permissions_view.dart';
import '../features/auth/presentation/auth_connection_view.dart';

import "../features/purchase_review/presentation/purchase_review_view.dart";
import "../features/supplier/presentation/supplier_view.dart";
import "../features/workflow_log/presentation/workflow_log_view.dart";
import "../features/work_queue/presentation/work_queue_view.dart";
import 'ui_preview.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  // Screen flow only; MyApp calls refresh() when the session or the Gmail
  // connection phase changes.
  redirect: (context, state) {
    if (kDebugMode && state.uri.path == '/ui-preview') return null;
    final container = ProviderScope.containerOf(context, listen: false);
    final session = container.read(authSessionViewModelProvider).asData?.value;
    final path = state.uri.path;
    // Read the Gmail connection only on the connection screen, where it is
    // being established anyway.
    final gmailReady =
        session?.isSignedIn == true &&
        path == '/login/connection' &&
        container.read(gmailConnectionViewModelProvider).connectionPhase ==
            GmailConnectionPhase.connected;
    return authRedirect(session?.status, path, gmailReady: gmailReady);
  },
  routes: [
    if (kDebugMode)
      GoRoute(
        path: '/ui-preview',
        builder: (context, state) =>
            UiPreviewApp(parameters: state.uri.queryParameters),
      ),
    GoRoute(path: '/login', builder: (context, state) => const LoginView()),
    GoRoute(
      path: '/login/permissions',
      builder: (context, state) => const AuthPermissionsView(),
    ),
    GoRoute(
      path: '/login/connection',
      builder: (context, state) => const AuthConnectionView(),
    ),
    GoRoute(path: '/account', builder: (context, state) => const AccountView()),
    GoRoute(path: '/', builder: (context, state) => const WorkQueueView()),
    // KAN-144 업무별 주소: 같은 업무 큐 화면에서 그 업무를 엽니다.
    GoRoute(
      path: '/cases/:caseId',
      builder: (context, state) =>
          WorkQueueView(caseId: state.pathParameters['caseId']),
    ),
    // SCR-010 실행 로그
    GoRoute(
      path: '/logs',
      builder: (context, state) => const WorkflowLogView(),
    ),
    // SCR-011 거래처 조회
    GoRoute(
      path: '/suppliers',
      builder: (context, state) => const SupplierView(),
    ),
    // SCR-002 검토 카드 (API-13·14·15)
    GoRoute(
      path: '/cases/:caseId/review',
      builder: (context, state) =>
          PurchaseReviewView(caseId: state.pathParameters['caseId']!),
    ),
  ],
);
