import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../app/app_paths.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../domain/purchase_review.dart";
import "../../domain/unresolved_line.dart";
import "../purchase_review_view_model.dart";
import "counter_offer_panel.dart";
import "plan_board.dart";
import "plan_card.dart";
import "quote_compare.dart";
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
  String? _selectedPlanId;

  @override
  void didUpdateWidget(ReviewCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.card.reviewRevision != _card.reviewRevision ||
        oldWidget.review.card.inputRevision != _card.inputRevision ||
        oldWidget.review.card.caseId != _card.caseId) {
      _selectedPlanId = null;
    }
  }

  /// The counter-offer panel, which the notice's "사유 보기" scrolls to.
  final _counterOfferKey = GlobalKey();

  /// The 확인할 항목 section, which "확인할 항목 보기" scrolls to.

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

  /// 상태 띠 아래 작은 줄: '견적 3곳 비교 · 확정 가능 2안 · 남도청과는 운송비
  /// 미확인으로 비교에서 제외'. 어느 안에도 들지 않은 업체의 미확인 줄은 이
  /// 문장으로 옮기고 목록에서 뺍니다.
  (String?, List<UnresolvedLine>) _summary(
    ReviewCard card,
    List<UnresolvedLine> lines,
  ) {
    final quotes = widget.review.sourceQuotes;
    if (quotes.isEmpty) return (null, lines);
    final rest = [...lines];
    final inPlans = {
      for (final plan in card.plans)
        for (final allocation in plan.allocations) allocation.supplierId,
    };
    final excluded = [
      if (card.plans.isNotEmpty)
        for (final quote in quotes)
          if (!inPlans.contains(quote.supplierId)) quote.supplierName,
    ];
    final parts = [
      "견적 ${quotes.length}곳 비교",
      if (card.plans.isNotEmpty)
        "확정 가능 ${card.plans.where((plan) => plan.valid).length}안",
      for (final name in {...excluded})
        () {
          final line = rest
              .where(
                (line) => line.label == name && line.text.endsWith("미확인"),
              )
              .firstOrNull;
          if (line == null) return "${josa(name, "은", "는")} 비교에서 제외";
          rest.remove(line);
          return "${josa(name, "은", "는")} ${line.text}으로 비교에서 제외";
        }(),
    ];
    return (parts.join(" · "), rest);
  }

  /// 맨 위 상태 띠(7.16): 이전 카드 · 확인할 것 · 결정 · 오류.
  List<Widget> _notices(ReviewCard card) {
    final (summary, lines) = _summary(
      card,
      unresolvedLines(card, quotes: widget.review.quotes),
    );
    return [
      if (card.isStale) ...[
        const _Notice(
          icon: Icons.history,
          text: "새 견적이나 조건이 반영돼 이 카드는 이전 결과입니다. 이 카드로는 선택하거나 확인할 수 없습니다.",
          tone: _Tone.danger,
        ),
        const SizedBox(height: 12),
      ],
      if (!card.outcome.ready ||
          lines.isNotEmpty ||
          card.questions.isNotEmpty) ...[
        _Notice(
          icon: card.questions.isNotEmpty
              ? Icons.error_outline
              : Icons.pause_circle_outline,
          text: card.outcome.message,
          questionCount: card.questions.length,
          summary: summary,
          // Red only when there is no plan at all; something left to check
          // (확인할 항목) is a caution; otherwise grey.
          tone: !card.outcome.ready
              ? (card.outcome.noPlan ? _Tone.danger : _Tone.caution)
              : card.questions.isNotEmpty
              ? _Tone.caution
              : _Tone.info,
          lines: lines,
          questions: card.questions,
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

  /// 영역 순서(7.16): 상태 띠 · 구매안 비교 · 확인할 항목 · 역제안 · 견적과
  /// 근거. 영역 사이 40, 제목→내용 16.
  List<Widget> _sections(BuildContext context, {required bool compact}) {
    final card = _card;
    final quotes = widget.review.sourceQuotes;
    final colors = SupplierColors.of(
      card,
      lowest: PlanBoard.lowestPlan(card.plans),
    );
    final offer = card.counterOffer;
    return [
      if (!compact) ...[
        _Head(card: card),
        const SizedBox(height: 20),
      ] else ...[
        Text(
          [
            "검토 ${card.reviewRevision}회차",
            if (card.createdAt != null)
              "${formatSeoulDateTime(card.createdAt!)} 저장",
          ].join(" · "),
          style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        ),
        const SizedBox(height: 12),
      ],
      ..._notices(card),
      const SizedBox(height: 28),
      const _SectionTitle(
        "구매안 비교",
        caption: "가장 낮은 안을 자동으로 고르지 않아요. 조건을 보고 직접 선택해 주세요. 총액은 서버 계산값이에요.",
      ),
      const SizedBox(height: 16),
      if (card.plans.isEmpty)
        const Text(
          "보여 줄 구매안이 없습니다.",
          style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        )
      else
        PlanBoard(
          card: card,
          busy: _busy,
          colors: colors,
          selectedPlanId: _selectedPlanId,
          onSelect: (plan) => setState(
            () => _selectedPlanId = _selectedPlanId == plan.planId
                ? null
                : plan.planId,
          ),
        ),
      if (offer != null) ...[
        const SizedBox(height: 40),
        AnimatedContainer(
          key: _counterOfferKey,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          // A spread shadow: a wash that reaches past the panel without
          // moving it.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LdsRadius.panel),
            boxShadow: [
              BoxShadow(
                color: caution.withValues(alpha: _offerMarked ? .16 : 0),
                spreadRadius: 10,
              ),
            ],
          ),
          child: CounterOfferPanel(
            offer: offer,
            onMailDraft: () =>
                showMailDraftDialog(context, caseId: card.caseId),
            plansSelectable:
                card.can(ReviewAction.selectPlan) &&
                card.plans.any((plan) => plan.selectable),
          ),
        ),
      ],
      const SizedBox(height: 40),
      _SectionTitle(
        "견적과 근거",
        caption: [
          "업체별 최신 견적을 같은 항목끼리 나란히 봐요.",
          ?QuoteCompare.commonNote(quotes),
        ].join(" "),
      ),
      const SizedBox(height: 16),
      if (quotes.isEmpty)
        const Text(
          "이 카드에 연결된 견적이 없습니다.",
          style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        )
      else
        QuoteCompare(quotes: quotes, colors: colors),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final compact = isCompactLayout(context);
    final actions = _ReviewActions(
      card: card,
      busy: _busy,
      onHold: _hold,
      selectedPlan: _card.plan(_selectedPlanId),
      onConfirm: _selectedPlanId == null
          ? _confirm
          : () => _run((vm) => vm.selectPlan(_card.plan(_selectedPlanId)!)),
      compact: compact,
    );
    if (compact) {
      // Phone: the card as its own screen; 보류 / 확인하고 보관 pinned below.
      return MobilePageScaffold(
        title: "검토 카드",
        onBack: () => context.go(AppPaths.task(card.caseId)),
        actions: [
          IconButton(
            tooltip: "메일 초안",
            onPressed: () => showMailDraftDialog(context, caseId: card.caseId),
            icon: const Icon(Icons.mail_outline),
          ),
        ],
        // Not a lazy list: "사유 보기" scrolls to the counter-offer panel,
        // which must exist while it is off screen.
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
            children: _sections(context, compact: true),
          ),
        ),
        bottomBar: actions.visible ? actions : null,
      );
    }
    // Web: the page scrolls; 보류 / 확인하고 보관 stay at the bottom.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey("review-card-scroll"),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _sections(context, compact: false),
            ),
          ),
        ),
        if (actions.visible) actions,
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

/// 머리: '← 업무 / 검토 카드' · 회차 · 저장 시각 · 입력 버전, 오른쪽 메일 초안.
class _Head extends StatelessWidget {
  const _Head({required this.card});

  final ReviewCard card;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LdsFocusRing(
                  radius: 4,
                  child: InkWell(
                    onTap: () => context.go(AppPaths.task(card.caseId)),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: 16,
                            color: LdsColors.mutedStrong,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "업무",
                            style: TextStyle(
                              fontSize: 13,
                              color: LdsColors.mutedStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Text(
                  "  /  검토 카드",
                  style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: LdsColors.lineSoft,
                    borderRadius: BorderRadius.circular(LdsRadius.button),
                  ),
                  child: Text(
                    "${card.reviewRevision}회차",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.ink,
                    ),
                  ),
                ),
                Text(
                  [
                    if (card.createdAt != null)
                      "${formatSeoulDateTime(card.createdAt!)} 저장",
                    "입력 버전 ${card.inputRevision}",
                  ].join("   "),
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdsColors.mutedStrong,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      LdsButton(
        label: "메일 초안",
        icon: Icons.mail_outline,
        variant: LdsButtonVariant.outlined,
        onPressed: () => showMailDraftDialog(context, caseId: card.caseId),
      ),
    ],
  );
}

/// 영역 제목 20/700 + 선택 배지 + 옆 설명 13.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.caption});

  final String text;
  final String? caption;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 4,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: LdsColors.ink,
              ),
            ),
          ),
        ],
      ),
      if (caption != null)
        Text(
          caption!,
          style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
        ),
    ],
  );
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.card,
    required this.busy,
    required this.onHold,
    required this.onConfirm,
    this.compact = false,
    this.selectedPlan,
  });

  final ReviewCard card;
  final bool busy;
  final VoidCallback onHold, onConfirm;
  final bool compact;
  final ResponsePlan? selectedPlan;

  String? get _holdBlocked => card.disabledMessage(ReviewAction.hold);
  String? get _confirmBlocked =>
      card.disabledMessage(ReviewAction.confirmReview);

  bool get visible =>
      card.can(ReviewAction.selectPlan) ||
      card.can(ReviewAction.hold) ||
      card.can(ReviewAction.confirmReview) ||
      _holdBlocked != null ||
      _confirmBlocked != null;

  @override
  Widget build(BuildContext context) {
    final canHold = card.can(ReviewAction.hold);
    final canConfirm = selectedPlan != null
        ? card.can(ReviewAction.selectPlan)
        : card.can(ReviewAction.confirmReview);
    final blocked = [
      for (final message in {?_holdBlocked, ?_confirmBlocked})
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        ),
    ];
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedPlan != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${selectedPlan!.typeLabel} · ${won(selectedPlan!.totalAmount)} 선택됨',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
                  child: Text(selectedPlan != null ? "이 안으로 확정" : "확인하고 보관"),
                ),
              ),
            ],
          ),
          ...blocked,
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LdsColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.touch_app_outlined,
                size: 18,
                color: LdsColors.mutedStrong,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedPlan == null
                      ? "구매안을 고르거나, 근거가 부족하면 보류해 주세요."
                      : "${selectedPlan!.typeLabel} · ${won(selectedPlan!.totalAmount)} 선택됨",
                  style: TextStyle(fontSize: 15, color: LdsColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              LdsButton(
                label: "보류",
                variant: LdsButtonVariant.outlinedNeutral,
                onPressed: canHold && !busy ? onHold : null,
              ),
              const SizedBox(width: 8),
              LdsButton(
                label: selectedPlan != null ? "이 안으로 확정" : "확인하고 보관",
                icon: Icons.check,
                onPressed: canConfirm && !busy ? onConfirm : null,
              ),
            ],
          ),
          ...blocked,
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

enum _Tone {
  /// Plain information: grey.
  info,

  /// Something is left to check: warning `#FFF8E4`/`#745300`.
  caution,

  /// A stop: an error, an outdated card, no plan.
  danger,
}

/// 한 줄 상태 띠 (`docs/design-ssot.md` 7.16): 확인할 항목이 있으면 경고,
/// 없으면 회색. 남은 것은 제목 아래 줄로, 역제안에 사유가 있는 것은 그리로
/// 가는 단추로 둡니다.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.tone = _Tone.info,
    this.lines = const [],
    this.questions = const [],
    this.questionCount = 0,
    this.summary,
    this.onCounterOffer,
  });

  final IconData icon;
  final String text;
  final _Tone tone;

  /// 확인할 항목 수. 있으면 제목이 '확인할 항목 N건 · 답에 따라 1위가 바뀔 수
  /// 있어요.'가 됩니다.
  final int questionCount;

  /// 맨 아래 작은 줄(견적 수 · 확정 가능 안 수 · 비교 제외).
  final String? summary;

  /// What is left unresolved, under the title.
  final List<UnresolvedLine> lines;
  final List<ReviewQuestion> questions;

  /// Shows the counter-offer panel, for a line whose reason is written there.
  final VoidCallback? onCounterOffer;

  @override
  Widget build(BuildContext context) {
    final (iconColor, background, border, body) = switch (tone) {
      _Tone.info => (
        context.palette.ink,
        LdsColors.lineSoft,
        LdsColors.line,
        LdsColors.ink,
      ),
      _Tone.caution => (
        caution,
        LdsColors.warningBg,
        const Color(0xFFFFE7A3),
        LdsColors.warningText,
      ),
      _Tone.danger => (
        danger,
        LdsColors.errorBg,
        const Color(0xFFFBD0D4),
        LdsColors.ink,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(LdsRadius.table),
        border: Border.all(color: border),
      ),
      child: Row(
        // 아이콘은 띠의 세로 가운데.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  questionCount > 0
                      ? TextSpan(
                          children: [
                            TextSpan(
                              text: "확인할 항목 $questionCount건",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: " · 답에 따라 1위가 바뀔 수 있어요."),
                          ],
                        )
                      : TextSpan(children: [TextSpan(text: text)]),
                  style: TextStyle(fontSize: 15, height: 1.5, color: body),
                ),
                for (final question in questions)
                  _QuestionRow(question: question),
                for (final line in lines)
                  if (line.inCounterOffer && onCounterOffer != null)
                    _JumpLine(
                      label: line.label ?? line.text,
                      color: body,
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
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            TextSpan(text: line.text),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: body,
                        ),
                      ),
                    ),
                if (summary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    summary!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: body.withValues(alpha: .85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 확인할 항목 한 줄: '우선 확인' 칩 + 업체·항목(굵게) + 이유·역전 기준.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({required this.question});

  final ReviewQuestion question;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDB8),
                borderRadius: BorderRadius.circular(LdsRadius.button),
              ),
              child: const Text(
                "우선 확인",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LdsColors.warningText,
                ),
              ),
            ),
          ),
          TextSpan(
            text: "${question.supplierName} · ${question.fieldLabel}  ",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: LdsColors.ink,
            ),
          ),
          TextSpan(
            text: [
              question.reason,
              if (question.breakEvenAmount != null)
                "역전 기준 ${won(question.breakEvenAmount)}",
              ?question.formula,
            ].join(" · "),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 15, height: 1.6, color: LdsColors.ink),
    ),
  );
}

/// One unresolved item whose reason is in the counter-offer panel: its name
/// and a way there, instead of the same sentence twice.
class _JumpLine extends StatelessWidget {
  const _JumpLine({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      button: true,
      child: Material(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(LdsRadius.table),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text("사유 보기", style: TextStyle(fontSize: 13, color: color)),
                Icon(Icons.chevron_right, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
