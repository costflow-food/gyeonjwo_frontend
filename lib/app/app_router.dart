import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_view.dart';
import '../features/auth/presentation/account_view.dart';
import '../features/auth/presentation/auth_permissions_view.dart';
import '../features/auth/presentation/auth_connection_view.dart';

import "../features/purchase_review/presentation/purchase_review_view.dart";
import "../features/work_queue/presentation/work_queue_view.dart";

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginView()),
    GoRoute(
      path: '/login/permissions',
      builder: (context, state) => const AuthPermissionsView(),
    ),
    GoRoute(
      path: '/login/connection',
      builder: (context, state) {
        final preview = AuthConnectionPreview.values.firstWhere(
          (value) => value.name == state.uri.queryParameters['state'],
          orElse: () => AuthConnectionPreview.connecting,
        );
        return AuthConnectionView(preview: preview);
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
