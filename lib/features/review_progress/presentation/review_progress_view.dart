import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/workspace_colors.dart";
import "../domain/review_progress_repository.dart";
import "review_progress_view_model.dart";
import "widgets/review_progress_body.dart";
import "widgets/review_progress_dialog.dart";

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
      backgroundColor: context.palette.surface,
      builder: (sheetContext) => ReviewProgressView(
        caseId: caseId,
        title: title,
        router: router,
        onViewCase: () {
          Navigator.of(sheetContext).pop();
          router.go("/cases/$caseId");
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
          router.go("/cases/$caseId");
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
  String? _openedAt;
  ModalRoute<Object?>? _route;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    final router = widget.router;
    if (router != null) {
      _openedAt = router.routerDelegate.currentConfiguration.uri.path;
      router.routerDelegate.addListener(_onRouteChanged);
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    widget.router?.routerDelegate.removeListener(_onRouteChanged);
    _lifecycle.dispose();
    super.dispose();
  }

  /// Closes this view when the screen behind it is no longer this case.
  /// Opening the case itself (업무 보기, /cases/:id/review) keeps it.
  void _onRouteChanged() {
    final router = widget.router;
    if (router == null || _closing || !mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final ownCase = "/cases/${widget.caseId}";
    if (path == _openedAt || path == ownCase || path.startsWith("$ownCase/")) {
      return;
    }
    _closing = true;
    // Not during the router's own notification: remove only this route,
    // whatever else is open on top of it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = _route;
      if (!mounted || route == null || !route.isActive) return;
      route.navigator?.removeRoute(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(reviewProgressViewModelProvider(widget.caseId));
    final current = value.asData?.value;
    final retry = ref
        .read(reviewProgressViewModelProvider(widget.caseId).notifier)
        .refresh;
    return ReviewProgressDialog(
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
    );
  }
}
