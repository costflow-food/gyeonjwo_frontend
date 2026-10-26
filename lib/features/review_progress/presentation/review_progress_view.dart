import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/sr003/review_progress/review_progress_dialog.dart';

import '../../work_queue/presentation/work_queue_view.dart';
import '../../work_queue/presentation/work_queue_view_model.dart';
import 'review_progress_view_model.dart';

class ReviewProgressView extends ConsumerStatefulWidget {
  const ReviewProgressView({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ReviewProgressView> createState() => _ReviewProgressViewState();
}

class _ReviewProgressViewState extends ConsumerState<ReviewProgressView> {
  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  @override
  void didUpdateWidget(covariant ReviewProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId) _startPreview();
  }

  void _startPreview() {
    Future.microtask(() {
      if (mounted) {
        ref.read(reviewProgressProvider.notifier).start(widget.requestId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(reviewProgressProvider)[widget.requestId] ?? 0;
    final queue = ref.watch(workQueueViewModelProvider).asData?.value;
    String supplier = widget.requestId;
    for (final request in queue?.requests ?? []) {
      if (request.id == widget.requestId) supplier = '${request.supplier} 요청';
    }

    return Stack(
      children: [
        const ExcludeSemantics(child: WorkQueueView()),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: const ModalBarrier(
              dismissible: false,
              color: Color(0x66000000),
            ),
          ),
        ),
        Center(
          child: ReviewProgressDialog(
            requestId: widget.requestId,
            supplier: supplier,
            step: step,
          ),
        ),
      ],
    );
  }
}
