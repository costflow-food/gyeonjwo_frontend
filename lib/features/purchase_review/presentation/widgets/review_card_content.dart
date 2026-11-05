import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/widgets/preview_button.dart";
import "../../../../shared/widgets/responsive_columns.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../domain/purchase_review.dart";
import "../purchase_review_view_model.dart";
import "counter_offer_panel.dart";
import "plan_card.dart";
import "quote_card.dart";
import "review_format.dart";

/// SCR-002 검토 카드: 구매안·역제안·확인 항목·근거 견적과 판단(API-15).
class ReviewCardContent extends ConsumerStatefulWidget {
  const ReviewCardContent({super.key, required this.review});

  final PurchaseReview review;

  @override
  ConsumerState<ReviewCardContent> createState() => _ReviewCardContentState();
}

class _ReviewCardContentState extends ConsumerState<ReviewCardContent> {
  bool _busy = false;
  String? _error;

  ReviewCard get _card => widget.review.card;

  Future<void> _run(
    Future<void> Function(PurchaseReviewViewModel viewModel) action,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(
        ref.read(purchaseReviewViewModelProvider(_card.caseId).notifier),
      );
      if (mounted) setState(() => _busy = false);
    } on PurchaseReviewFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요."
            : failure.cardChanged
            ? "카드가 바뀌어 저장하지 못했어요. 최신 카드를 다시 불러왔어요. (${failure.message})"
            : failure.message;
      });
    }
  }

  Future<void> _hold() async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _HoldDialog(),
    );
    if (note == null || !mounted) return;
    await _run((viewModel) => viewModel.hold(note));
  }

  Future<void> _confirm() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("검토 확인"),
        content: const Text("이 카드로 검토를 마치고 업무를 보관할까요? 보관한 업무는 업무 큐에서 빠져요."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("취소"),
          ),
          FilledButton(
            style: WorkspaceButtonStyles.filled,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("확인하고 보관"),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _run((viewModel) => viewModel.confirmReview());
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final quotes = widget.review.sourceQuotes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "PURCHASE REVIEW",
          style: TextStyle(
            color: accent,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "검토 카드",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    "검토 ${card.reviewRevision}회차",
                    if (card.createdAt != null)
                      "${formatSeoulDateTime(card.createdAt!)} 저장",
                  ].join(" · "),
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PreviewButton(
                  "업무로 돌아가기",
                  icon: Icons.arrow_back,
                  onPressed: () => context.go("/cases/${card.caseId}"),
                ),
                PreviewButton(
                  "메일 초안",
                  icon: Icons.drafts_outlined,
                  onPressed: () =>
                      showMailDraftDialog(context, caseId: card.caseId),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (card.isStale) ...[
          const _Notice(
            icon: Icons.history,
            text: "새 견적이나 조건이 반영돼 이 카드는 이전 결과예요. 이 카드로는 선택하거나 확인할 수 없어요.",
            strong: true,
          ),
          const SizedBox(height: 12),
        ],
        _Notice(
          icon: card.outcome.ready
              ? Icons.check_circle_outline
              : Icons.pause_circle_outline,
          text: card.outcome.message,
          strong: !card.outcome.ready,
          details: card.unresolved,
        ),
        if (card.decision != null) ...[
          const SizedBox(height: 12),
          _Notice(icon: Icons.task_alt, text: _decisionText(card)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: _Notice(
              icon: Icons.error_outline,
              text: _error!,
              strong: true,
            ),
          ),
        ],
        const SizedBox(height: 28),
        const _Heading("구매안"),
        const SizedBox(height: 12),
        if (card.plans.isEmpty)
          const Text(
            "보여 줄 구매안이 없어요.",
            style: TextStyle(fontSize: 12, color: muted),
          )
        else
          ResponsiveColumns(
            minItemWidth: 280 * textScale,
            children: [
              for (final plan in card.plans)
                PlanCard(
                  key: ValueKey("plan-${plan.planId}"),
                  plan: plan,
                  card: card,
                  busy: _busy,
                  onSelect: () => _run((viewModel) => viewModel.selectPlan(plan)),
                ),
            ],
          ),
        if (card.counterOffer != null) ...[
          const SizedBox(height: 28),
          const _Heading("역제안"),
          const SizedBox(height: 12),
          CounterOfferPanel(offer: card.counterOffer!),
        ],
        if (card.questions.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _Heading("확인할 항목"),
          const SizedBox(height: 12),
          for (final question in card.questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinePanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${question.supplierName} · ${question.fieldLabel}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(question.reason, style: const TextStyle(fontSize: 12)),
                    if (question.formula != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        question.formula!,
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ] else if (question.breakEvenAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "역전 기준 ${won(question.breakEvenAmount)}",
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 28),
        const _Heading("견적과 근거"),
        const SizedBox(height: 12),
        if (quotes.isEmpty)
          const Text(
            "이 카드에 연결된 견적이 없어요.",
            style: TextStyle(fontSize: 12, color: muted),
          )
        else
          ResponsiveColumns(
            minItemWidth: 280 * textScale,
            children: [
              for (final quote in quotes)
                QuoteCard(key: ValueKey("quote-${quote.quoteId}"), quote: quote),
            ],
          ),
        const SizedBox(height: 28),
        _Actions(card: card, busy: _busy, onHold: _hold, onConfirm: _confirm),
        const SizedBox(height: 16),
      ],
    );
  }

  static String _decisionText(ReviewCard card) {
    final decision = card.decision!;
    return switch (decision.decision) {
      ReviewAction.selectPlan => () {
        final plan = card.plan(decision.planId);
        return plan == null
            ? "구매안을 선택했어요."
            : "선택한 구매안: ${plan.typeLabel} · ${won(plan.totalAmount)}";
      }(),
      ReviewAction.hold =>
        "검토를 보류했어요.${decision.note == null ? "" : " 사유: ${decision.note}"}",
      ReviewAction.confirmReview => "검토를 확인하고 보관했어요.",
      _ => "판단이 저장됐어요.",
    };
  }
}

/// 보류·확인. 서버가 허용한 동작만 누를 수 있고, 막힌 동작은 이유를 보여 줍니다.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.card,
    required this.busy,
    required this.onHold,
    required this.onConfirm,
  });

  final ReviewCard card;
  final bool busy;
  final VoidCallback onHold, onConfirm;

  @override
  Widget build(BuildContext context) {
    final holdBlocked = card.disabledMessage(ReviewAction.hold);
    final confirmBlocked = card.disabledMessage(ReviewAction.confirmReview);
    final canHold = card.can(ReviewAction.hold);
    final canConfirm = card.can(ReviewAction.confirmReview);
    if (!canHold && !canConfirm && holdBlocked == null && confirmBlocked == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (canHold || holdBlocked != null)
              OutlinedButton(
                style: WorkspaceButtonStyles.outlined,
                onPressed: canHold && !busy ? onHold : null,
                child: const Text("검토 보류"),
              ),
            if (canConfirm || confirmBlocked != null)
              FilledButton(
                style: WorkspaceButtonStyles.filled,
                onPressed: canConfirm && !busy ? onConfirm : null,
                child: const Text("검토 확인"),
              ),
          ],
        ),
        for (final message in [?holdBlocked, ?confirmBlocked])
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ),
      ],
    );
  }
}

class _HoldDialog extends StatefulWidget {
  const _HoldDialog();

  @override
  State<_HoldDialog> createState() => _HoldDialogState();
}

class _HoldDialogState extends State<_HoldDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = _note.text.trim();
    return AlertDialog(
      title: const Text("검토 보류"),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _note,
          autofocus: true,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: "보류 사유",
            hintText: "예: 역제안 회신을 기다린 뒤 결정",
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("취소"),
        ),
        FilledButton(
          style: WorkspaceButtonStyles.filled,
          onPressed: note.isEmpty ? null : () => Navigator.of(context).pop(note),
          child: const Text("보류"),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.strong = false,
    this.details = const [],
  });

  final IconData icon;
  final String text;
  final bool strong;
  final List<String> details;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: strong ? blush : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: strong ? accent : ink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: strong ? accent : ink,
                ),
              ),
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "· $detail",
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
