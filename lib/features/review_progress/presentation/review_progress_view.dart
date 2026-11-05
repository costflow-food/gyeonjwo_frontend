import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../shared/widgets/async_content.dart";
import "../../work_queue/domain/work_case.dart";
import "../domain/review_phase.dart";
import "review_progress_view_model.dart";
import "widgets/review_progress_body.dart";
import "widgets/review_progress_dialog.dart";

/// SCR-003 검토 진행. START·RESUME가 접수된 뒤 API-03 단계를 보여 줍니다.
Future<void> showReviewProgressDialog(
  BuildContext context, {
  required String caseId,
  required String title,
}) {
  // Capture navigation before the step change can rebuild the caller.
  final router = GoRouter.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: ReviewProgressView(
        caseId: caseId,
        title: title,
        onViewCase: () {
          Navigator.of(dialogContext).pop();
          router.go("/cases/$caseId");
        },
      ),
    ),
  );
}

class ReviewProgressView extends ConsumerWidget {
  const ReviewProgressView({
    super.key,
    required this.caseId,
    required this.title,
    required this.onViewCase,
  });

  final String caseId, title;
  final VoidCallback onViewCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reviewProgressViewModelProvider(caseId);
    final value = ref.watch(provider);
    final progress = value.asData?.value;
    return ReviewProgressDialog(
      title: title,
      outcome: progress == null ? null : outcomeOf(progress.processingStep),
      onClose: () => Navigator.of(context).pop(),
      onViewCase: onViewCase,
      body: AsyncContent<CaseProgress>(
        // Keep the steps on screen while a poll reloads.
        value: progress == null ? value : AsyncData(progress),
        onRetry: ref.read(provider.notifier).refresh,
        builder: (progress) => ReviewProgressBody(progress: progress),
      ),
    );
  }
}
