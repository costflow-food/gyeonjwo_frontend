import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/purchase_review.dart";
import "dashed_border.dart";
import "review_format.dart";

/// 역제안 영역: 제목 '역제안' + 설명, 그 아래 노란 점선 상자.
///
/// 상자: 상태 라벨 · '확정 견적이 아니에요' 안내 · 오른쪽 '역제안 메일 초안',
/// 제안 문장(20/700), 요청·인상 전 대비 차이, '단가 범위 · 제안 조건 자세히
/// 보기'. 보류된 역제안은 제안 문장 대신 사유를 적습니다.
class CounterOfferPanel extends StatefulWidget {
  const CounterOfferPanel({
    super.key,
    required this.offer,
    required this.onMailDraft,
    this.plansSelectable = false,
  });

  final CounterOffer offer;
  final VoidCallback onMailDraft;

  /// Whether a plan can still be chosen on this card; a held offer says so.
  final bool plansSelectable;

  static const _border = Color(0xFFF5CF6B);

  /// "−400원/kg (−6.9%)": 기준 대비 차이.
  static String delta(String value, String base, String? unit) {
    final a = num.tryParse(value), b = num.tryParse(base);
    if (a == null || b == null) return '';
    final d = a - b;
    return '${d >= 0 ? '+' : '−'}${perUnitTight(d.abs().toString(), unit)}'
        '${b == 0 ? '' : ' (${d >= 0 ? '+' : '−'}${(d.abs() / b * 100).toStringAsFixed(1)}%)'}';
  }

  @override
  State<CounterOfferPanel> createState() => _CounterOfferPanelState();
}

class _CounterOfferPanelState extends State<CounterOfferPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final target = offer.target;
    final reference = offer.reference;
    final unit = reference?.unit;
    final range = reference?.allowedRange ?? const [];
    final summary = [
      if (range.length == 2)
        "${decimal(range.first)}원 ~ ${decimal(range.last)}원",
      if (reference?.alternativeTotal != null)
        "대안 총액 ${won(reference!.alternativeTotal)}",
    ];
    // A held offer proposes nothing: its reason is the content, there is no
    // empty range box, and the draft button shows only when a draft exists.
    final hold = offer.onHold;
    final hasRange = range.length == 2;
    final showRange = !hold || summary.isNotEmpty;
    final showDraft = !hold || offer.draftIds.isNotEmpty;
    const muted = TextStyle(
      fontSize: 13,
      color: LdsColors.mutedStrong,
      height: 1.6,
    );
    final comparisons = [
      if (target != null && reference?.requestedUnitPrice != null)
        (
          '요청 ${perUnitTight(reference!.requestedUnitPrice, unit)} 대비 ',
          CounterOfferPanel.delta(
            target.targetUnitPrice,
            reference.requestedUnitPrice!,
            unit,
          ),
        ),
      if (target != null && reference?.previousUnitPrice != null)
        (
          '인상 전 ${perUnitTight(reference!.previousUnitPrice, unit)} 대비 ',
          CounterOfferPanel.delta(
            target.targetUnitPrice,
            reference.previousUnitPrice!,
            unit,
          ),
        ),
    ];
    final price = target == null
        ? null
        : perUnitTight(target.targetUnitPrice, unit);
    final head = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hold)
          _HoldChip(offer.statusLabel)
        else
          LdsTag(offer.statusLabel, style: LdsTagStyle.solid),
        if (!hold)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: LdsColors.cautionText),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  "상대가 수락하기 전까지 확정 견적이 아니에요",
                  style: TextStyle(fontSize: 13, color: LdsColors.cautionText),
                ),
              ),
            ],
          ),
      ],
    );
    final draftButton = LdsButton(
      label: "역제안 메일 초안",
      icon: Icons.mail_outline,
      variant: LdsButtonVariant.outlined,
      onPressed: widget.onMailDraft,
    );
    final box = CustomPaint(
      foregroundPainter: const DashedBorderPainter(
        color: CounterOfferPanel._border,
        radius: LdsRadius.panel,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        decoration: BoxDecoration(
          color: LdsColors.warningBg,
          borderRadius: BorderRadius.circular(LdsRadius.panel),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좁으면 메일 초안 단추가 라벨 줄 아래로 내려갑니다.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [head, if (showDraft) draftButton],
            ),
            if (target != null) ...[
              const SizedBox(height: 10),
              // A long name wraps inside the panel instead of pushing past it.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: target.supplierName),
                    TextSpan(text: "에 ${josa(price!, "을", "를")} 제안해요"),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: LdsColors.ink,
                ),
              ),
            ],
            if (comparisons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    for (final (index, (label, value)) in comparisons.indexed) ...[
                      if (index > 0) const TextSpan(text: " · "),
                      TextSpan(text: label),
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: LdsColors.title,
                        ),
                      ),
                    ],
                  ],
                ),
                style: muted,
              ),
            ],
            if (hold && offer.reason != null) ...[
              const SizedBox(height: 12),
              Text(
                offer.reason!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: LdsColors.ink,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _DetailsToggle(
              open: _open,
              onTap: () => setState(() => _open = !_open),
            ),
            if (_open) ...[
              if (showRange) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: LdsColors.line),
                    borderRadius: BorderRadius.circular(LdsRadius.table),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Held with no range: the box holds only the
                        // alternative total, so it is named for that.
                        hold && !hasRange ? "대안 총액" : "제안 가능 범위",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LdsColors.label,
                        ),
                      ),
                      if (summary.isNotEmpty)
                        Text(
                          hold && !hasRange
                              ? won(reference!.alternativeTotal)
                              : summary.join(" · "),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: LdsColors.ink,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final condition in [...?target?.conditions])
                Text("조건 · $condition", style: muted),
              if (!hold && offer.reason != null)
                Text(offer.reason!, style: muted),
            ],
            if (offer.draftIds.isNotEmpty)
              const Text(
                "역제안 메일 초안은 '역제안 메일 초안'에서 확인하고 승인해 주세요.",
                style: muted,
              ),
            if (hold && target == null && !hasRange)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LdsRadius.table),
                ),
                child: Text.rich(
                  TextSpan(
                    text: "목표 단가와 제안 범위는 정해지지 않았습니다.",
                    children: [
                      if (widget.plansSelectable)
                        TextSpan(
                          text: " 구매안은 그대로 고를 수 있습니다.",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.palette.ink,
                          ),
                        ),
                    ],
                  ),
                  style: muted,
                ),
              ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Semantics(
              header: true,
              child: const Text(
                "역제안",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: LdsColors.ink,
                ),
              ),
            ),
            const Text(
              "기존 업체와 거래를 이어 가기 위한 제안이에요. 구매안과 따로 판단해요.",
              style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
            ),
          ],
        ),
        const SizedBox(height: 16),
        box,
      ],
    );
  }
}

/// '▶ 단가 범위 · 제안 조건 자세히 보기': 열리면 아래 삼각형.
class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      expanded: open,
      child: LdsFocusRing(
        radius: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  open ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 18,
                  color: LdsColors.title,
                ),
                const Flexible(
                  child: Text(
                    "단가 범위 · 제안 조건 자세히 보기",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// "역제안 보류" in the caution colour.
class _HoldChip extends StatelessWidget {
  const _HoldChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: cautionTint,
      borderRadius: BorderRadius.circular(LdsRadius.button),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_outline, size: 13, color: caution),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: caution,
          ),
        ),
      ],
    ),
  );
}
