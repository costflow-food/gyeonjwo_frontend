import 'package:go_router/go_router.dart';

import '../features/purchase_review/purchase_review_view.dart';
import '../features/work_queue/work_queue_view.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WorkQueueView()),
    GoRoute(
      path: '/review',
      builder: (context, state) => const PurchaseReviewView(),
    ),
  ],
);
