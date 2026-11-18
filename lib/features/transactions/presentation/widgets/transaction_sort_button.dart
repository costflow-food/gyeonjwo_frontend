import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/transaction_listing.dart";

/// 정렬 선택지 하나: 이름 + 기준 열 + 큰 값부터인지.
typedef TransactionSortChoice = ({
  String label,
  TransactionSort sort,
  bool descending,
});

/// 목록 위 오른쪽 정렬 선택 '최신순 ▾' (표 열 머리 정렬을 대신합니다).
/// 같은 값은 날짜 최신순([TransactionListing.build]).
class TransactionSortButton extends StatefulWidget {
  const TransactionSortButton({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final TransactionsFilter filter;
  final void Function(TransactionSort sort, {required bool descending})
  onChanged;

  static const List<TransactionSortChoice> choices = [
    (label: "최신순", sort: TransactionSort.date, descending: true),
    (label: "오래된순", sort: TransactionSort.date, descending: false),
    (label: "단가 높은순", sort: TransactionSort.unitPrice, descending: true),
    (label: "단가 낮은순", sort: TransactionSort.unitPrice, descending: false),
    (label: "총액 높은순", sort: TransactionSort.total, descending: true),
    (label: "총액 낮은순", sort: TransactionSort.total, descending: false),
    (label: "수량 많은순", sort: TransactionSort.quantity, descending: true),
    (label: "수량 적은순", sort: TransactionSort.quantity, descending: false),
  ];

  /// 지금 정렬의 이름.
  static String labelOf(TransactionsFilter filter) => choices
      .firstWhere(
        (choice) =>
            choice.sort == filter.sort &&
            choice.descending == filter.descending,
        orElse: () => choices.first,
      )
      .label;

  @override
  State<TransactionSortButton> createState() => _TransactionSortButtonState();
}

class _TransactionSortButtonState extends State<TransactionSortButton> {
  final _focus = FocusNode(debugLabel: "sort button");
  bool _open = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    setState(() => _open = true);
    final current = TransactionSortButton.labelOf(widget.filter);
    final picked = await Navigator.of(context).push(
      LdsPopoverRoute<TransactionSortChoice>(
        anchor: LdsPopoverRoute.anchorOf(context),
        label: "정렬 닫기",
        child: _SortMenu(current: current),
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    _focus.requestFocus();
    if (picked != null) {
      widget.onChanged(picked.sort, descending: picked.descending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = TransactionSortButton.labelOf(widget.filter);
    final radius = BorderRadius.circular(LdsRadius.button);
    return Semantics(
      button: true,
      label: "정렬, $label",
      excludeSemantics: true,
      onTap: _show,
      child: LdsFocusRing(
        radius: LdsRadius.button,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: _open ? LdsColors.title : LdsColors.borderStrong,
            ),
          ),
          child: InkWell(
            focusNode: _focus,
            onTap: _show,
            borderRadius: radius,
            hoverColor: LdsColors.canvas,
            child: Container(
              height: 36,
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      letterSpacing: -.3,
                      color: LdsColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: LdsColors.title,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 정렬 창: 선택지 8개(줄 44), 지금 정렬은 굵게 + 주황 체크.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final choice in TransactionSortButton.choices)
            _choiceRow(context, choice, selected: choice.label == current),
        ],
      ),
    ),
  );

  Widget _choiceRow(
    BuildContext context,
    TransactionSortChoice choice, {
    required bool selected,
  }) {
    void pick() => Navigator.of(context).pop(choice);
    return Semantics(
      selected: selected,
      button: true,
      label: "${choice.label} 정렬",
      excludeSemantics: true,
      onTap: pick,
      child: InkWell(
        autofocus: selected,
        onTap: pick,
        hoverColor: LdsColors.canvas,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  choice.label,
                  style: TextStyle(
                    fontSize: 15,
                    letterSpacing: -.3,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: LdsColors.ink,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 18, color: LdsColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
