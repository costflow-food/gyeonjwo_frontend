import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/widgets/preview_button.dart";
import "../../../../shared/widgets/responsive_columns.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../domain/purchase_review.dart";
import "../../domain/unresolved_line.dart";
import "../purchase_review_view_model.dart";
import "counter_offer_panel.dart";
import "plan_board.dart";
import "quote_card.dart";
import "review_format.dart";

class ReviewCardContent extends ConsumerStatefulWidget {
  const ReviewCardContent({super.key, required this.review});

  final PurchaseReview review;

  @override
  ConsumerState<ReviewCardContent> createState() => _ReviewCardContentState();
}

class _ReviewCardContentState extends ConsumerState<ReviewCardContent> {
  bool _busy = false;
  String? _error;

  /// The counter-offer panel, which the notice's "사유 보기" scrolls to.
  final _counterOfferKey = GlobalKey();

  /// The panel is marked for a moment after "사유 보기": on a wide screen it
  /// is already in view and nothing would move.
  bool _offerMarked = false;
  Timer? _offerMark;

  ReviewCard get _card => widget.review.card;

  @override
  void dispose() {
    _offerMark?.cancel();
    super.dispose();
  }

  Future<void> _showCounterOffer() async {
    final target = _counterOfferKey.currentContext;
    if (target == null) return;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final panel = target.findRenderObject();
    final viewport = Scrollable.maybeOf(target)?.position.viewportDimension;
    final tall =
        panel is RenderBox && viewport != null && panel.size.height > viewport;
    // A panel taller than the screen goes to its top, where the reason is.
    // Otherwise it is brought in whole, from whichever side it is cut off,
    // and one already in view stays put.
    for (final policy
        in tall
            ? const [ScrollPositionAlignmentPolicy.explicit]
            : const [
                ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                ScrollPositionAlignmentPolicy.keepVisibleAtStart,
              ]) {
      if (!target.mounted) return;
      await Scrollable.ensureVisible(
        target,
        alignmentPolicy: policy,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _offerMarked = true);
    _offerMark?.cancel();
    _offerMark = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _offerMarked = false);
    });
  }

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
      // Phone: the buttons stay pinned while the notice above may be
      // scrolled away, so the failure is also said over the page.
      if (isCompactLayout(context)) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_error!)));
      }
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

  List<Widget> _notices(ReviewCard card) {
    final lines = unresolvedLines(card, quotes: widget.review.quotes);
    return [
      if (card.isStale) ...[
        const _Notice(
          icon: Icons.history,
          text: "새 견적이나 조건이 반영돼 이 카드는 이전 결과입니다. 이 카드로는 선택하거나 확인할 수 없습니다.",
          tone: _Tone.danger,
        ),
        const SizedBox(height: 12),
      ],
      if (!card.outcome.ready || lines.isNotEmpty) ...[
        _Notice(
          icon: Icons.pause_circle_outline,
          text: card.outcome.message,
          // Red only when there is no plan at all; something left to check
          // is a caution.
          tone: card.outcome.ready
              ? _Tone.info
              : card.outcome.noPlan
              ? _Tone.danger
              : _Tone.caution,
          lines: lines,
          onCounterOffer: _showCounterOffer,
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
            tone: _Tone.danger,
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  /// Phone: the card as its own screen; 보류 / 확인하고 보관 pinned below.
  Widget _page(BuildContext context) {
    final card = _card;
    final quotes = widget.review.sourceQuotes;
    final actions = _ReviewActions(
      card: card,
      busy: _busy,
      onHold: _hold,
      onConfirm: _confirm,
    );
    return MobilePageScaffold(
      title: "검토 카드",
      onBack: () => context.go("/cases/${card.caseId}"),
      actions: [
        IconButton(
          tooltip: "메일 초안",
          onPressed: () => showMailDraftDialog(context, caseId: card.caseId),
          icon: const Icon(Icons.mail_outline),
        ),
      ],
      // Not a lazy list: "사유 보기" scrolls to the counter-offer panel, which
      // must exist while it is off screen.
      body: SingleChildScrollView(
        key: const ValueKey("review-card-scroll"),
        // Without the pinned bar nothing else keeps the end of the page
        // clear of the system navigation bar.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24 + (actions.visible ? 0 : MediaQuery.paddingOf(context).bottom),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                "검토 ${card.reviewRevision}회차",
                if (card.createdAt != null)
                  "${formatSeoulDateTime(card.createdAt!)} 저장",
              ].join(" · "),
              style: TextStyle(fontSize: 13, color: context.palette.muted),
            ),
            const SizedBox(height: 10),
            if (_RaiseCard.from(card, widget.review.quotes, compact: true)
                case final raise?) ...[
              raise,
              const SizedBox(height: 12),
            ],
            ..._notices(card),
            if (card.plans.isEmpty)
              Text(
                "보여 줄 구매안이 없습니다.",
                style: TextStyle(fontSize: 13, color: context.palette.muted),
              )
            else
              PlanBoard(
                card: card,
                busy: _busy,
                folding: true,
                onSelect: (plan) =>
                    _run((viewModel) => viewModel.selectPlan(plan)),
              ),
            const SizedBox(height: 20),
            _SidePanel(
              card: card,
              busy: _busy,
              showActions: false,
              counterOfferKey: _counterOfferKey,
              counterOfferMarked: _offerMarked,
              onHold: _hold,
              onConfirm: _confirm,
              onMailDraft: () =>
                  showMailDraftDialog(context, caseId: card.caseId),
            ),
            const SizedBox(height: 28),
            const _Heading("견적과 근거"),
            const SizedBox(height: 12),
            if (quotes.isEmpty)
              Text(
                "이 카드에 연결된 견적이 없습니다.",
                style: TextStyle(fontSize: 13, color: context.palette.muted),
              )
            else
              for (final quote in quotes) ...[
                QuoteCard(
                  key: ValueKey("quote-${quote.quoteId}"),
                  quote: quote,
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
      bottomBar: actions.visible ? actions : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCompactLayout(context)) return _page(context);
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
        ..._notices(card),
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
          counterOfferKey: _counterOfferKey,
          counterOfferMarked: _offerMarked,
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

class _RaiseCard extends StatelessWidget {
  const _RaiseCard({
    required this.supplierName,
    required this.previous,
    required this.requested,
    required this.unit,
    required this.effectiveFrom,
    this.compact = false,
  });

  final String supplierName;
  final String previous, requested;
  final String? unit, effectiveFrom;

  /// Phone: prices on one line, smaller.
  final bool compact;

  static _RaiseCard? from(
    ReviewCard card,
    List<QuoteVersion> quotes, {
    bool compact = false,
  }) {
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
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 18 : 24),
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
            compact
                ? "${decimal(previous)} → ${decimal(requested)}"
                : "${decimal(previous)}\n→ ${decimal(requested)}",
            style: TextStyle(
              fontSize: compact ? 28 : 52,
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

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.card,
    required this.busy,
    required this.counterOfferKey,
    required this.counterOfferMarked,
    required this.onHold,
    required this.onConfirm,
    required this.onMailDraft,
    this.showActions = true,
  });

  final ReviewCard card;
  final bool busy;
  final Key counterOfferKey;

  /// Draws a soft caution wash behind the counter-offer panel.
  final bool counterOfferMarked;
  final VoidCallback onHold, onConfirm, onMailDraft;

  /// False on a phone, where the buttons are pinned to the bottom instead.
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final actions = _ReviewActions(
      card: card,
      busy: busy,
      onHold: onHold,
      onConfirm: onConfirm,
    );
    final offer = card.counterOffer;
    if (offer == null && card.questions.isEmpty && !showActions) {
      return const SizedBox.shrink();
    }
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
            AnimatedContainer(
              key: counterOfferKey,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              // A spread shadow: a wash that reaches past the panel without
              // moving it.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: caution.withValues(
                      alpha: counterOfferMarked ? .16 : 0,
                    ),
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: CounterOfferPanel(
                offer: offer,
                onMailDraft: onMailDraft,
                plansSelectable:
                    card.can(ReviewAction.selectPlan) &&
                    card.plans.any((plan) => plan.selectable),
              ),
            ),
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
          if (showActions && actions.visible) actions,
        ],
      ),
    );
  }
}

/// 보류 / 확인하고 보관, with the reason when one is blocked.
class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.card,
    required this.busy,
    required this.onHold,
    required this.onConfirm,
  });

  final ReviewCard card;
  final bool busy;
  final VoidCallback onHold, onConfirm;

  String? get _holdBlocked => card.disabledMessage(ReviewAction.hold);
  String? get _confirmBlocked =>
      card.disabledMessage(ReviewAction.confirmReview);

  bool get visible =>
      card.can(ReviewAction.hold) ||
      card.can(ReviewAction.confirmReview) ||
      _holdBlocked != null ||
      _confirmBlocked != null;

  @override
  Widget build(BuildContext context) {
    final canHold = card.can(ReviewAction.hold);
    final canConfirm = card.can(ReviewAction.confirmReview);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        for (final message in {?_holdBlocked, ?_confirmBlocked})
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: context.palette.muted),
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

enum _Tone {
  /// Plain information.
  info,

  /// Something is left to check.
  caution,

  /// A stop: an error, an outdated card, no plan.
  danger,
}

/// Text on the fixed caution and danger tints, which stay light in dark mode.
const _onTint = Color(0xFF26302D);

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.tone = _Tone.info,
    this.lines = const [],
    this.onCounterOffer,
  });

  final IconData icon;
  final String text;
  final _Tone tone;

  /// What is left unresolved, under the title.
  final List<UnresolvedLine> lines;

  /// Shows the counter-offer panel, for a line whose reason is written there.
  final VoidCallback? onCounterOffer;

  @override
  Widget build(BuildContext context) {
    final (color, background, body) = switch (tone) {
      _Tone.info => (context.palette.ink, context.palette.blush, null),
      _Tone.caution => (caution, cautionTint, _onTint),
      _Tone.danger => (danger, dangerTint, _onTint),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                for (final line in lines)
                  if (line.inCounterOffer && onCounterOffer != null)
                    _JumpLine(
                      label: line.label ?? line.text,
                      color: body ?? context.palette.ink,
                      background: body == null
                          ? context.palette.surface
                          : Colors.white,
                      onTap: onCounterOffer!,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "· "),
                            if (line.label != null)
                              TextSpan(
                                text: line.text.isEmpty
                                    ? line.label
                                    : "${line.label} · ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            TextSpan(text: line.text),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: body,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One unresolved item whose reason is in the counter-offer panel: its name
/// and a way there, instead of the same sentence twice.
class _JumpLine extends StatelessWidget {
  const _JumpLine({
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color color, background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      button: true,
      child: Material(
        color: background.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "사유 보기",
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: .75),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: color.withValues(alpha: .75),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
