import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/workspace_colors.dart';
import '../../../features/review_progress/presentation/review_progress_view_model.dart';
import 'review_progress_header.dart';
import 'review_progress_body.dart';
import 'review_progress_footer.dart';

class ReviewProgressDialog extends StatelessWidget {
  const ReviewProgressDialog({
    super.key,
    required this.requestId,
    required this.supplier,
    required this.step,
  });
  final String requestId, supplier;
  final int step;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: MediaQuery.sizeOf(context).height - 40,
      ),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: '검토 진행',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReviewProgressHeader(
                supplier: supplier,
                onClose: () => context.go('/'),
              ),
              const Divider(height: 1, color: line),
              ReviewProgressBody(step: step),
              const Divider(height: 1, color: line),
              ReviewProgressFooter(
                complete: step >= reviewSteps.length,
                onViewResult: () => context.go(
                  Uri(
                    path: '/review',
                    queryParameters: {'requestId': requestId},
                  ).toString(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
