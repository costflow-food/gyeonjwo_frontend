import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/purchase_record.dart";
import "../../domain/transaction_listing.dart";
import "../transaction_format.dart";

/// 단가 아래 13px '직전 대비'(`docs/design-ssot.md` 7.12): ▲ `#E42939`,
/// ▼ `#1B64DA`, 첫 거래·직전과 같음 `#8A95A0`. 직전 거래가 있으면 툴팁.
class PriceChangeText extends StatelessWidget {
  const PriceChangeText(this.record, this.change, {super.key});

  final PurchaseRecord record;
  final PriceChange change;

  @override
  Widget build(BuildContext context) {
    final color = change.isFirst || change.difference == 0
        ? LdsColors.outline
        : change.difference > 0
        ? LdsColors.priceUp
        : LdsColors.priceDown;
    final text = changeText(record, change);
    final tooltip = changeTooltip(change);
    final moved = !change.isFirst && change.difference != 0;
    final label = Semantics(
      label: tooltip == null
          ? text
          : "$text, $tooltip${moved ? (change.difference > 0 ? " 올랐어요" : " 내렸어요") : ""}",
      excludeSemantics: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    return tooltip == null ? label : Tooltip(message: tooltip, child: label);
  }
}
