import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_route_policy.dart';
import '../features/auth/domain/gmail_connection.dart';
import '../features/auth/presentation/auth_session_view_model.dart';
import '../features/auth/presentation/login_view.dart';
import '../features/auth/presentation/account_view.dart';
import '../features/auth/presentation/auth_permissions_view.dart';
import '../features/auth/presentation/auth_connection_view.dart';

import "../features/purchase_review/presentation/purchase_review_view.dart";
import "../features/work_queue/presentation/work_queue_view.dart";

final appRouter = GoRouter(
  initialLocation: '/login',
  // Screen flow only; MyApp calls refresh() when the session changes.
  redirect: (context, state) {
    final session = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authSessionViewModelProvider).asData?.value;
    return authRedirect(session?.status, state.uri.path);
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginView()),
    GoRoute(
      path: '/login/permissions',
      builder: (context, state) => const AuthPermissionsView(),
    ),
    GoRoute(
      path: '/login/connection',
      builder: (context, state) {
        final previewName = state.uri.queryParameters['state'];
        final previewPhase = GmailConnectionPhase.values
            .where((value) => value.name == previewName)
            .firstOrNull;
        return AuthConnectionView(previewPhase: previewPhase);
      },
    ),
    GoRoute(path: '/account', builder: (context, state) => const AccountView()),
    GoRoute(path: '/', builder: (context, state) => const WorkQueueView()),
    GoRoute(
      path: '/review',
      builder: (context, state) => PurchaseReviewView(
        requestId:
            state.uri.queryParameters["requestId"] ?? "REQ-2026-1019-003",
      ),
    ),
  ],
);
