import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/workspace_shell.dart';
import '../../../shared/widgets/async_content.dart';
import '../domain/purchase_review.dart';
import 'purchase_review_view_model.dart';
import '../../../widgets/sr003/purchase_review/purchase_review_content.dart';

class PurchaseReviewView extends ConsumerWidget {
  const PurchaseReviewView({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = purchaseReviewViewModelProvider(requestId);
    return WorkspaceShell(
      child: AsyncContent<PurchaseReview>(
        value: ref.watch(provider),
        onRetry: ref.read(provider.notifier).refresh,
        builder: (review) => PurchaseReviewContent(review: review),
      ),
    );
  }
}
