import 'package:go_router/go_router.dart';

import "../features/purchase_review/presentation/purchase_review_view.dart";
import "../features/work_queue/presentation/work_queue_view.dart";

final appRouter = GoRouter(
  routes: [
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
