import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../shared/widgets/close_on_case_leave.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../domain/review_progress_repository.dart";
import "review_progress_view_model.dart";
import "widgets/review_progress_body.dart";
import "widgets/review_progress_dialog.dart";
import "../../../app/app_paths.dart";

Future<void> showReviewProgressDialog(
  BuildContext context, {
  required String caseId,
  required String title,
}) {
  // Capture navigation before the step change can rebuild the caller.
  final router = GoRouter.of(context);
  if (isCompactLayout(context)) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => ReviewProgressView(
        caseId: caseId,
        title: title,
        router: router,
        onViewCase: () {
          Navigator.of(sheetContext).pop();
          router.go(AppPaths.task(caseId));
        },
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: ReviewProgressView(
        caseId: caseId,
        title: title,
        router: router,
        onViewCase: () {
          Navigator.of(dialogContext).pop();
          router.go(AppPaths.task(caseId));
        },
      ),
    ),
  );
}

class ReviewProgressView extends ConsumerStatefulWidget {
  const ReviewProgressView({
    super.key,
    required this.caseId,
    required this.title,
    required this.onViewCase,
    this.router,
  });

  final String caseId, title;
  final VoidCallback onViewCase;

  /// When given, the view closes itself once the app moves to a screen that
  /// is not this case (e.g. another case picked in the queue).
  final GoRouter? router;

  @override
  ConsumerState<ReviewProgressView> createState() => _ReviewProgressViewState();
}

class _ReviewProgressViewState extends ConsumerState<ReviewProgressView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A hidden tab or a backgrounded app asks nothing until it is back.
    _lifecycle = AppLifecycleListener(
      onStateChange: (lifecycle) {
        final viewModel = ref.read(
          reviewProgressViewModelProvider(widget.caseId).notifier,
        );
        switch (lifecycle) {
          case AppLifecycleState.resumed:
            viewModel.resume();
          case AppLifecycleState.hidden ||
              AppLifecycleState.paused ||
              AppLifecycleState.detached:
            viewModel.pause();
          case AppLifecycleState.inactive:
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(reviewProgressViewModelProvider(widget.caseId));
    final current = value.asData?.value;
    final retry = ref
        .read(reviewProgressViewModelProvider(widget.caseId).notifier)
        .refresh;
    return CloseOnCaseLeave(
      router: widget.router,
      caseId: widget.caseId,
      child: ReviewProgressDialog(
        title: widget.title,
        outcome: current?.outcome,
        onClose: () => Navigator.of(context).pop(),
        onViewCase: widget.onViewCase,
        body: switch (value) {
          // Keep the steps on screen while a check reloads.
          _ when current != null => ReviewProgressBody(
            state: current,
            onRetry: retry,
          ),
          AsyncError(:final error) => ReviewProgressError(
            failure: error is ReviewProgressFailure ? error : null,
            onRetry: retry,
          ),
          _ => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ),
    );
  }
}
