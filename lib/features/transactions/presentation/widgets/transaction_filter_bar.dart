import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/transaction_listing.dart";

/// 필터 바 `[leading(기간)] [품목 ▾] [거래처 ▾] [확정 방식 ▾]` + 고른 값
/// 태그 줄 + '모두 지우기' (`docs/design-ssot.md` 7.12).
class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    super.key,
    required this.listing,
    required this.filter,
    required this.onItems,
    required this.onSuppliers,
    required this.onMethods,
    required this.onClearAll,
    this.leading,
  });

  final TransactionListing listing;
  final TransactionsFilter filter;
  final ValueChanged<Set<String>> onItems;
  final ValueChanged<Set<String>> onSuppliers;
  final ValueChanged<Set<String>> onMethods;
  final VoidCallback onClearAll;

  /// 필터 줄 맨 앞(기간 선택).
  final Widget? leading;

  static const _caption = "최근 거래순";

  static List<LdsFilterOption> _options(List<FilterChoice> choices) => [
    for (final choice in choices) LdsFilterOption(choice.value, choice.count),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final buttons = <Widget>[
            LdsFilterButton(
              padding: const EdgeInsets.only(left: 8, right: 4),
              label: "품목",
              caption: _caption,
              options: _options(listing.itemChoices),
              selected: filter.items,
              onChanged: onItems,
            ),
            LdsFilterButton(
              padding: const EdgeInsets.only(left: 8, right: 4),
              label: "거래처",
              caption: _caption,
              options: _options(listing.supplierChoices),
              selected: filter.suppliers,
              onChanged: onSuppliers,
            ),
            LdsFilterButton(
              padding: const EdgeInsets.only(left: 8, right: 4),
              label: "확정 방식",
              caption: _caption,
              options: _options(listing.methodChoices),
              selected: filter.methods,
              onChanged: onMethods,
            ),
          ];
          // 기간 버튼은 필요한 폭만 사용하고, 공간이 부족할 때만 줄입니다.
          // 좁은 화면이나 선택 개수 배지가 있으면 자연스럽게 줄을 바꿉니다.
          if (constraints.maxWidth >= 340 && !filter.hasFilters) {
            return Row(
              children: [
                if (leading != null) ...[
                  Flexible(child: leading!),
                  const SizedBox(width: 4),
                ],
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  buttons[i],
                ],
              ],
            );
          }
          return Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [?leading, ...buttons],
          );
        },
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
