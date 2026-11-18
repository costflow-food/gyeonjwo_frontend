import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/transaction_listing.dart";

/// 필터 바 `[품목 ▾] [거래처 ▾]` + 오른쪽 [trailing](정렬 선택) + 고른 값
/// 태그 줄 + '모두 지우기' (`docs/design-ssot.md` 7.12). 확정 방식은 DB에
/// 없어 두지 않습니다.
class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    super.key,
    required this.listing,
    required this.filter,
    required this.onItems,
    required this.onSuppliers,
    required this.onMethods,
    required this.onClearAll,
    this.trailing,
  });

  final TransactionListing listing;
  final TransactionsFilter filter;
  final ValueChanged<Set<String>> onItems;
  final ValueChanged<Set<String>> onSuppliers;
  final ValueChanged<Set<String>> onMethods;
  final VoidCallback onClearAll;

  /// 필터 줄 오른쪽 끝(정렬 선택).
  final Widget? trailing;

  static const _caption = "최근 거래순";

  static List<LdsFilterOption> _options(List<FilterChoice> choices) => [
    for (final choice in choices) LdsFilterOption(choice.value, choice.count),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          LdsFilterButton(
            label: "품목",
            caption: _caption,
            options: _options(listing.itemChoices),
            selected: filter.items,
            onChanged: onItems,
          ),
          LdsFilterButton(
            label: "거래처",
            caption: _caption,
            options: _options(listing.supplierChoices),
            selected: filter.suppliers,
            onChanged: onSuppliers,
          ),
          LdsFilterButton(
            label: "확정 방식",
            caption: _caption,
            options: _options(listing.methodChoices),
            selected: filter.methods,
            onChanged: onMethods,
          ),
          ?trailing,
        ],
      ),
      if (filter.hasFilters) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final item in filter.items)
              LdsRemovableTag(
                item,
                onRemove: () => onItems({...filter.items}..remove(item)),
              ),
            for (final method in filter.methods)
              LdsRemovableTag(
                method,
                onRemove: () => onMethods({...filter.methods}..remove(method)),
              ),
            for (final supplier in filter.suppliers)
              LdsRemovableTag(
                supplier,
                onRemove: () =>
                    onSuppliers({...filter.suppliers}..remove(supplier)),
              ),
            _ClearAll(onTap: onClearAll),
          ],
        ),
      ],
    ],
  );
}

/// 밑줄 글자 단추 '모두 지우기' 14px `#4E5968`.
class _ClearAll extends StatelessWidget {
  const _ClearAll({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: "모두 지우기",
    excludeSemantics: true,
    onTap: onTap,
    child: LdsFocusRing(
      radius: LdsRadius.button,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LdsRadius.button),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: const Text(
            "모두 지우기",
            style: TextStyle(
              fontSize: 14,
              color: LdsColors.label,
              decoration: TextDecoration.underline,
              decorationColor: LdsColors.label,
            ),
          ),
        ),
      ),
    ),
  );
}
