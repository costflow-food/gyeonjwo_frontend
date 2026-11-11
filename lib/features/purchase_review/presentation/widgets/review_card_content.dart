import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/preview_button.dart";
import "../../../../shared/widgets/responsive_columns.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../domain/purchase_review.dart";
import "../purchase_review_view_model.dart";
import "counter_offer_panel.dart";
import "plan_board.dart";
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
            ? "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."
            : failure.cardChanged
            ? "카드가 바뀌어 저장하지 못했습니다. 최신 카드를 다시 불러왔습니다. (${failure.message})"
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
        content: const Text("이 카드로 검토를 마치고 업무를 보관하시겠습니까? 보관한 업무는 업무 큐에서 빠집니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("취소"),
          ),
          FilledButton(
            style: WorkspaceButtonStyles.filled(context),
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
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    "검토 ${card.reviewRevision}회차",
                    if (card.createdAt != null)
                      "${formatSeoulDateTime(card.createdAt!)} 저장",
                  ].join(" · "),
                  style: TextStyle(fontSize: 13, color: context.palette.muted),
                ),
                const SizedBox(height: 6),
                const Text(
                  "검토 카드",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PreviewButton(
                  "업무로 돌아가기",
                  onPressed: () => context.go("/cases/${card.caseId}"),
                ),
                PreviewButton(
                  "메일 초안",
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
            text: "새 견적이나 조건이 반영돼 이 카드는 이전 결과입니다. 이 카드로는 선택하거나 확인할 수 없습니다.",
            strong: true,
          ),
          const SizedBox(height: 12),
        ],
        if (!card.outcome.ready || card.unresolved.isNotEmpty) ...[
          _Notice(
            icon: Icons.pause_circle_outline,
            text: card.outcome.message,
            strong: !card.outcome.ready,
            details: card.unresolved,
          ),
          const SizedBox(height: 12),
        ],
        if (card.decision != null) ...[
          _Notice(icon: Icons.task_alt, text: _decisionText(card)),
          const SizedBox(height: 12),
        ],
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: _Notice(
              icon: Icons.error_outline,
              text: _error!,
              strong: true,
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        if (card.plans.isEmpty)
          Text(
            "보여 줄 구매안이 없습니다.",
            style: TextStyle(fontSize: 13, color: context.palette.muted),
          )
        else
          PlanBoard(
            card: card,
            busy: _busy,
            onSelect: (plan) => _run((viewModel) => viewModel.selectPlan(plan)),
          ),
      ],
    );
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_RaiseCard.from(card, widget.review.quotes) case final raise?) ...[
          raise,
          const SizedBox(height: 16),
        ],
        _SidePanel(
          card: card,
          busy: _busy,
          onHold: _hold,
          onConfirm: _confirm,
          onMailDraft: () => showMailDraftDialog(context, caseId: card.caseId),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideWidth = 320 * textScale;
            if (constraints.maxWidth < 640 * textScale + sideWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [main, const SizedBox(height: 24), side],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 20),
                SizedBox(width: sideWidth, child: side),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        const _Heading("견적과 근거"),
        const SizedBox(height: 12),
        if (quotes.isEmpty)
          Text(
            "이 카드에 연결된 견적이 없습니다.",
            style: TextStyle(fontSize: 13, color: context.palette.muted),
          )
        else
          ResponsiveColumns(
            minItemWidth: 280 * textScale,
            children: [
              for (final quote in quotes)
                QuoteCard(
                  key: ValueKey("quote-${quote.quoteId}"),
                  quote: quote,
                ),
            ],
          ),
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
            ? "구매안을 선택했습니다."
            : "선택한 구매안: ${plan.typeLabel} · ${won(plan.totalAmount)}";
      }(),
      ReviewAction.hold =>
        "검토를 보류했습니다.${decision.note == null ? "" : " 사유: ${decision.note}"}",
      ReviewAction.confirmReview => "검토를 확인하고 보관했습니다.",
      _ => "판단이 저장됐습니다.",
    };
  }
}

/// 인상 요청: 역제안 대상 업체가 올린 단가(인상 전 → 요청).
class _RaiseCard extends StatelessWidget {
  const _RaiseCard({
    required this.supplierName,
    required this.previous,
    required this.requested,
    required this.unit,
    required this.effectiveFrom,
  });

  final String supplierName;
  final String previous, requested;
  final String? unit, effectiveFrom;

  static _RaiseCard? from(ReviewCard card, List<QuoteVersion> quotes) {
    final offer = card.counterOffer;
    final reference = offer?.reference;
    final target = offer?.target;
    if (target == null ||
        reference?.previousUnitPrice == null ||
        reference?.requestedUnitPrice == null) {
      return null;
    }
    final quote = quotes
        .where((quote) => quote.supplierId == target.supplierId)
        .firstOrNull;
    return _RaiseCard(
      supplierName: target.supplierName,
      previous: reference!.previousUnitPrice!,
      requested: reference.requestedUnitPrice!,
      unit: reference.unit,
      effectiveFrom: quote?.effectiveFrom,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.palette.accentText, context.palette.deep],
      ),
      boxShadow: [
        BoxShadow(
          color: context.palette.ink.withValues(alpha: 0.18),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$supplierName 인상 요청",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "${decimal(previous)}\n→ ${decimal(requested)}",
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w600,
              height: 1.05,
              letterSpacing: -.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              "원${unit == null ? "" : "/$unit"}",
              if (effectiveFrom != null)
                "${effectiveFrom!.replaceAll("-", ".")}부터",
            ].join(" · "),
            style: TextStyle(fontSize: 14, color: context.palette.onDeepMuted),
          ),
        ],
      ),
    ),
  );
}

/// 역제안 · 확인할 항목 · 보류/확인하고 보관.
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.card,
    required this.busy,
    required this.onHold,
    required this.onConfirm,
    required this.onMailDraft,
  });

  final ReviewCard card;
  final bool busy;
  final VoidCallback onHold, onConfirm, onMailDraft;

  @override
  Widget build(BuildContext context) {
    final holdBlocked = card.disabledMessage(ReviewAction.hold);
    final confirmBlocked = card.disabledMessage(ReviewAction.confirmReview);
    final canHold = card.can(ReviewAction.hold);
    final canConfirm = card.can(ReviewAction.confirmReview);
    final showActions =
        canHold || canConfirm || holdBlocked != null || confirmBlocked != null;
    final offer = card.counterOffer;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.palette.ink.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offer != null) ...[
            CounterOfferPanel(offer: offer, onMailDraft: onMailDraft),
            const SizedBox(height: 24),
          ],
          if (card.questions.isNotEmpty) ...[
            Row(
              children: [
                const _Heading("확인할 항목"),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palette.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "${card.questions.length}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.palette.onAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final question in card.questions)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: context.palette.line),
                    bottom: BorderSide(color: context.palette.line),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${question.supplierName} ${question.fieldLabel}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (question.breakEvenAmount != null)
                          Text(
                            "역전 기준 ${won(question.breakEvenAmount)}",
                            style: TextStyle(
                              fontSize: 13,
                              color: context.palette.muted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      question.reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
          if (showActions) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: WorkspaceButtonStyles.outlined(context).copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(48),
                      ),
                    ),
                    onPressed: canHold && !busy ? onHold : null,
                    child: const Text("보류"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: WorkspaceButtonStyles.filled(context).copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(48),
                      ),
                    ),
                    onPressed: canConfirm && !busy ? onConfirm : null,
                    child: const Text("확인하고 보관"),
                  ),
                ),
              ],
            ),
            for (final message in {?holdBlocked, ?confirmBlocked})
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  message,
                  style: TextStyle(fontSize: 12, color: context.palette.muted),
                ),
              ),
          ],
        ],
      ),
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
          style: WorkspaceButtonStyles.filled(context),
          onPressed: note.isEmpty
              ? null
              : () => Navigator.of(context).pop(note),
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
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
      color: strong ? dangerTint : context.palette.blush,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: strong ? danger : context.palette.ink),
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
                  color: strong ? danger : context.palette.ink,
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
