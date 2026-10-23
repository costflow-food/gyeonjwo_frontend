import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:go_router/go_router.dart';

import "review_progress_view_model.dart";
import 'widgets/review_progress_dialog.dart';

String _reviewLocation(String requestId) =>
    Uri(path: "/review", queryParameters: {"requestId": requestId}).toString();

/// 요청을 실행하고 진행 다이얼로그를 엽니다.
///
/// 이미 끝난 실행이면 같은 결과를 보도록 검토 화면으로 바로 이동합니다.
void showReviewProgress(
  BuildContext context,
  WidgetRef ref, {
  required String requestId,
  required String supplier,
}) {
  final state = ref.read(reviewProgressViewModelProvider(requestId));
  if (state.progress?.isComplete ?? false) {
    context.go(_reviewLocation(requestId));
    return;
  }
  showDialog<void>(
    context: context,
    builder: (_) =>
        ReviewProgressView(requestId: requestId, supplier: supplier),
  );
}

class ReviewProgressView extends ConsumerWidget {
  const ReviewProgressView({
    super.key,
    required this.requestId,
    required this.supplier,
  });

  final String requestId;
  final String supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reviewProgressViewModelProvider(requestId);
    ref.listen<ReviewProgressState>(provider, (previous, next) {
      final finished = next.progress?.isComplete ?? false;
      final wasFinished = previous?.progress?.isComplete ?? false;
      if (!finished || wasFinished) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go(_reviewLocation(requestId));
    });
    final state = ref.watch(provider);
    final progress = state.progress;
    void close() => Navigator.of(context).pop();
    return ReviewProgressDialog(
      supplier: supplier,
      currentStep: (progress?.completedSteps ?? 0).clamp(
        0,
        reviewProgressSteps.length,
      ),
      demo: progress?.synthetic ?? false,
      errorText: state.failed ? '진행 상태를 확인하지 못했습니다.' : null,
      onClose: close,
      onGoToQueue: close,
    );
  }
}
