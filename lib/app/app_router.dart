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

import "../features/dashboard/presentation/dashboard_view.dart";
import "../features/purchase_review/presentation/purchase_review_view.dart";
import "../features/supplier/presentation/supplier_view.dart";
import "../features/transactions/domain/transaction_listing.dart";
import "../features/transactions/presentation/transactions_view.dart";
import "../features/work_queue/domain/task_group.dart";
import "../features/workflow_log/presentation/workflow_log_view.dart";
import "../features/work_queue/presentation/work_queue_view.dart";
import "app_config.dart";
import "app_paths.dart";
import "dev/widget_preview_view.dart";
import "not_found_view.dart";

/// LDS 공통 위젯 미리보기. debug 빌드에서만 있고 로그인 없이 열립니다.
const devWidgetsPath = "/dev/widgets";

/// `/tasks?tab=` 상태 탭. 없거나 `all`이면 전체입니다.
TaskGroup? _tab(GoRouterState state) =>
    TaskGroup.fromCode(state.uri.queryParameters['tab']);

/// 옛 주소 `/cases/:id`, `/cases/:id/review`. 메일·로그에 남은 링크가 새
/// `/tasks` 주소로 열립니다.
final legacyCaseRoute = GoRoute(
  path: '/cases/:caseId',
  redirect: (context, state) => legacyCaseRedirect(state.uri),
  routes: [
    GoRoute(
      path: 'review',
      redirect: (context, state) => legacyCaseRedirect(state.uri),
    ),
  ],
);

final appRouter = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) => const NotFoundView(),
  // Screen flow only; MyApp calls refresh() when the session or the Gmail
  // connection phase changes.
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final session = container.read(authSessionViewModelProvider).asData?.value;
    final path = state.uri.path;
    if (kDebugMode && path == devWidgetsPath) return null;
    // DEV 존은 로그인 없이 고정 DEV 사용자로 바로 엽니다.
    if (AppConfig.loginDisabled) return noLoginRedirect(path);
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
        path: devWidgetsPath,
        builder: (context, state) => const WidgetPreviewView(),
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
    GoRoute(
      path: AppPaths.account,
      builder: (context, state) => const AccountView(),
    ),
    GoRoute(
      path: AppPaths.dashboard,
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: AppPaths.tasks,
      builder: (context, state) => WorkQueueView(tab: _tab(state)),
    ),
    GoRoute(
      path: '${AppPaths.tasks}/:caseId',
      builder: (context, state) => WorkQueueView(
        caseId: state.pathParameters['caseId'],
        tab: _tab(state),
      ),
    ),
    GoRoute(
      path: '${AppPaths.tasks}/:caseId/review',
      builder: (context, state) =>
          PurchaseReviewView(caseId: state.pathParameters['caseId']!),
    ),
    GoRoute(
      path: AppPaths.transactions,
      builder: (context, state) => TransactionsView(
        entry: TransactionsEntry(
          supplierItemId: state.uri.queryParameters["supplier_item"],
          itemName: state.uri.queryParameters["item"],
          date: state.uri.queryParameters["date"],
        ),
      ),
    ),
    GoRoute(
      path: AppPaths.suppliers,
      builder: (context, state) => const SupplierView(),
    ),
    GoRoute(
      path: AppPaths.logs,
      builder: (context, state) => const WorkflowLogView(),
    ),
    legacyCaseRoute,
  ],
);
