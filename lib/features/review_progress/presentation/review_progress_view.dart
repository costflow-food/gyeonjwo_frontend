import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../shared/widgets/async_content.dart";
import "../domain/review_phase.dart";
import "review_progress_view_model.dart";
import "widgets/review_progress_body.dart";
import "widgets/review_progress_dialog.dart";

Future<void> showReviewProgressDialog(
  BuildContext context, {
  required String requestId,
  required String supplier,
}) {
  // Capture navigation before progress can remove this row from a status filter.
  final router = GoRouter.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(
    container.read(reviewProgressViewModelProvider(requestId).notifier).start(),
  );
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: ReviewProgressView(
        requestId: requestId,
        supplier: supplier,
        onViewResult: () {
          Navigator.of(dialogContext).pop();
          router.go(
            Uri(
              path: "/review",
              queryParameters: {"requestId": requestId},
            ).toString(),
          );
        },
      ),
    ),
  );
}

class ReviewProgressView extends ConsumerWidget {
  const ReviewProgressView({
    super.key,
    required this.requestId,
    required this.supplier,
    required this.onViewResult,
  });

  final String requestId, supplier;
  final VoidCallback onViewResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reviewProgressViewModelProvider(requestId);
    final value = ref.watch(provider);
    return ReviewProgressDialog(
      supplier: supplier,
      complete: value.asData?.value == ReviewPhase.completed,
      onClose: () => Navigator.of(context).pop(),
      onViewResult: onViewResult,
      body: AsyncContent<ReviewPhase>(
        value: value,
        onRetry: () => ref.read(provider.notifier).start(),
        builder: (_) => const ReviewProgressBody(),
      ),
    );
  }
}
