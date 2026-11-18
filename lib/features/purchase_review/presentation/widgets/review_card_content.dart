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

  /// The counter-offer panel, which the notice's "사유 보기" scrolls to.
  final _counterOfferKey = GlobalKey();

  /// The 확인할 항목 section, which "확인할 항목 보기" scrolls to.
  final _questionsKey = GlobalKey();

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

  /// 맨 위 한 줄 상태 띠(7.16): 이전 카드 · 확인할 것 · 결정 · 오류.
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
      if (!card.outcome.ready ||
          lines.isNotEmpty ||
          card.questions.isNotEmpty) ...[
        _Notice(
          icon: Icons.pause_circle_outline,
          text: card.outcome.message,
          // Red only when there is no plan at all; something left to check
          // (확인할 항목) is a caution; otherwise grey.
          tone: !card.outcome.ready
              ? (card.outcome.noPlan ? _Tone.danger : _Tone.caution)
              : card.questions.isNotEmpty
              ? _Tone.caution
              : _Tone.info,
          lines: lines,
          onCounterOffer: _showCounterOffer,
          count: card.questions.length,
          onQuestions: card.questions.isEmpty ? null : _showQuestions,
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

  /// '확인할 항목 보기': 확인할 항목 영역으로 내려갑니다.
  Future<void> _showQuestions() async {
    final target = _questionsKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
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
        caption: "가장 낮은 안을 자동으로 고르지 않습니다. 조건을 보고 직접 선택해 주세요. 총액은 서버 계산값입니다.",
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
          onSelect: (plan) => _run((viewModel) => viewModel.selectPlan(plan)),
        ),
      if (card.questions.isNotEmpty) ...[
        const SizedBox(height: 40),
        _SectionTitle(
          "확인할 항목",
          key: _questionsKey,
          count: card.questions.length,
          caption: "답에 따라 순위가 바뀔 수 있는 값입니다. 보완 질문은 메일 초안에서 보냅니다.",
        ),
        const SizedBox(height: 16),
        _Questions(questions: card.questions),
      ],
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
      const _SectionTitle("견적과 근거", caption: "업체별 최신 견적을 같은 항목끼리 나란히 봅니다."),
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
      onConfirm: _confirm,
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
        variant: LdsButtonVariant.outlinedNeutral,
        onPressed: () => showMailDraftDialog(context, caseId: card.caseId),
      ),
    ],
  );
}

/// 영역 제목 20/700 + 선택 배지 + 옆 설명 13.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key, this.caption, this.count});

  final String text;
  final String? caption;
  final int? count;

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
          if (count != null) ...[
            const SizedBox(width: 8),
            LdsBadge(count!, tone: LdsBadgeTone.primary),
          ],
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

/// 확인할 항목: 업체·항목, 이유, 역전 기준·계산식.
class _Questions extends StatelessWidget {
  const _Questions({required this.questions});

  final List<ReviewQuestion> questions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perRow = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 640
          ? 2
          : 1;
      final width = (constraints.maxWidth - 16 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final question in questions)
            SizedBox(width: width, child: _QuestionCard(question)),
        ],
      );
    },
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard(this.question);

  final ReviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final detail = [
      ?question.formula,
      if (question.breakEvenAmount != null)
        "역전 기준 ${won(question.breakEvenAmount)}",
    ];
    // 왼쪽 경고 막대 3: 모서리가 둥근 틀은 테두리 색이 한 가지여야 해서
    // 막대를 안쪽에 그립니다.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LdsRadius.panel),
        border: Border.all(color: LdsColors.line),
      ),
      foregroundDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: LdsColors.warning, width: 3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "${question.supplierName} · ${question.fieldLabel}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: LdsColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.reason,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: LdsColors.ink,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LdsColors.canvas,
                borderRadius: BorderRadius.circular(LdsRadius.table),
              ),
              child: Text(
                detail.join("\n"),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: LdsColors.mutedStrong,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 보류 / 확인하고 보관, with the reason when one is blocked. On the web a
/// bar at the bottom of the page with a one-line guide (7.16).
class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.card,
    required this.busy,
    required this.onHold,
    required this.onConfirm,
    this.compact = false,
  });

  final ReviewCard card;
  final bool busy;
  final VoidCallback onHold, onConfirm;
  final bool compact;

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
              const Expanded(
                child: Text(
                  "구매안을 고르거나, 근거가 부족하면 보류해 주세요.",
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
                label: "확인하고 보관",
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
    this.onCounterOffer,
    this.count = 0,
    this.onQuestions,
  });

  final IconData icon;
  final String text;
  final _Tone tone;

  /// What is left unresolved, under the title.
  final List<UnresolvedLine> lines;

  /// Shows the counter-offer panel, for a line whose reason is written there.
  final VoidCallback? onCounterOffer;

  /// 확인할 항목 수와 그 영역으로 가는 '확인할 항목 보기'.
  final int count;
  final VoidCallback? onQuestions;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (count > 0) ...[
                        TextSpan(
                          text: "확인할 항목 $count건",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: " · "),
                      ],
                      TextSpan(text: text),
                    ],
                  ),
                  style: TextStyle(fontSize: 15, height: 1.5, color: body),
                ),
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
              ],
            ),
          ),
          if (onQuestions != null) ...[
            const SizedBox(width: 12),
            LdsFocusRing(
              radius: 4,
              child: InkWell(
                onTap: onQuestions,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "확인할 항목 보기",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: body,
                      decoration: TextDecoration.underline,
                      decorationColor: body,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
