import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../shared/widgets/workspace_button_styles.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../../../shared/workspace_colors.dart";
import "../domain/purchase_review.dart";
import "purchase_review_view_model.dart";
import "widgets/review_card_content.dart";

/// `/cases/{case_id}/review`: 업무 한 건의 저장 검토 카드.
class PurchaseReviewView extends ConsumerWidget {
  const PurchaseReviewView({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = purchaseReviewViewModelProvider(caseId);
    final value = ref.watch(provider);
    final current = value.asData?.value;
    return WorkspaceShell(
      child: switch (value) {
        // Keep the card on screen while it reloads after a decision.
        _ when current != null => ReviewCardContent(review: current),
        AsyncError(:final error) => _Unavailable(
          caseId: caseId,
          failure: error is PurchaseReviewFailure ? error : null,
          onRetry: ref.read(provider.notifier).refresh,
        ),
        _ => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.caseId,
    required this.failure,
    required this.onRetry,
  });

  final String caseId;
  final PurchaseReviewFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final notReady = failure?.notReady ?? false;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notReady ? Icons.hourglass_empty : Icons.error_outline,
              size: 28,
              color: notReady ? muted : accent,
            ),
            const SizedBox(height: 12),
            Text(
              notReady ? "아직 검토 카드가 없어요." : "검토 카드를 불러오지 못했어요.",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              notReady
                  ? "회신 검토가 끝나면 카드가 생겨요. 진행 상황은 업무에서 확인할 수 있어요."
                  : failure?.message ?? "잠시 뒤 다시 시도해 주세요.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: muted, height: 1.6),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  style: WorkspaceButtonStyles.outlined,
                  onPressed: () => context.go("/cases/$caseId"),
                  child: const Text("업무 보기"),
                ),
                FilledButton(
                  style: WorkspaceButtonStyles.filled,
                  onPressed: onRetry,
                  child: Text(notReady ? "다시 확인" : "다시 시도"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
