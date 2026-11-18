import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_focus_ring.dart';
import 'lds_tag.dart';

/// Tab text의 탭 하나. [count]가 있으면 옆에 숫자 배지를 둡니다.
class LdsTabItem<T> {
  const LdsTabItem({
    required this.value,
    required this.label,
    this.count,
    this.urgent = false,
  });

  final T value;
  final String label;
  final int? count;

  /// 선택되지 않았을 때 배지를 주황(primary)으로: '확인 필요' 탭(7.14).
  final bool urgent;
}

/// 상태 필터 탭 — LIKELION Tab text (`docs/design-ssot.md` 6.1, 4.2).
///
/// 칸 사이 20, 아래 1px `#E5E7EA` 선. 글자 15px `#4E5968`, 선택 시 `#191F28`
/// + 아래 2px `#191F28` 막대. 배지는 선택 = dark, [LdsTabItem.urgent] = primary,
/// 그 외 = neutral.
class LdsTabBar<T> extends StatelessWidget {
  const LdsTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.expand = false,
  });

  final List<LdsTabItem<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  /// 각 탭을 같은 폭으로 나눠 가용 너비 전체를 채웁니다.
  final bool expand;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LdsColors.line)),
    ),
    child: expand
        ? Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: _Tab(
                    tab: tab,
                    selected: tab.value == selected,
                    onTap: () => onSelected(tab.value),
                    fitLabel: true,
                  ),
                ),
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (index, tab) in tabs.indexed) ...[
                  if (index > 0) const SizedBox(width: 20),
                  _Tab(
                    tab: tab,
                    selected: tab.value == selected,
                    onTap: () => onSelected(tab.value),
                  ),
                ],
              ],
            ),
          ),
  );
}

class _Tab<T> extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.fitLabel = false,
  });

  final LdsTabItem<T> tab;
  final bool selected;
  final VoidCallback onTap;
  final bool fitLabel;

  @override
  Widget build(BuildContext context) {
    final count = tab.count;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tab.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? LdsColors.ink : LdsColors.label,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          LdsBadge(
            count,
            tone: selected
                ? LdsBadgeTone.dark
                : tab.urgent
                ? LdsBadgeTone.primary
                : LdsBadgeTone.neutral,
          ),
        ],
      ],
    );
    return Semantics(
      selected: selected,
      button: true,
      label: count == null ? tab.label : '${tab.label} $count건',
      // 자식 의미를 빼므로 누르기 동작은 여기서 다시 붙입니다.
      onTap: onTap,
      excludeSemantics: true,
      child: LdsFocusRing(
        radius: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: fitLabel ? double.infinity : null,
            height: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? LdsColors.ink : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: fitLabel
                ? FittedBox(fit: BoxFit.scaleDown, child: label)
                : label,
          ),
        ),
      ),
    );
  }
}

/// Tab round (`docs/design-ssot.md` 6.1): 둥근 칩형 탭. 문체 선택·빠른 기간
/// 선택처럼 몇 개 중 하나를 고를 때.
///
/// 높이 32, 모서리 16. 고른 칩 = `#333D4B` 바탕 흰 글자 700, 나머지 = 흰 바탕
/// 1px `#D1D6DC` · `#4E5968` 글자.
class LdsRoundTabs<T> extends StatelessWidget {
  const LdsRoundTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<LdsTabItem<T>> tabs;
  final T selected;

  /// null이면 누를 수 없습니다.
  final ValueChanged<T>? onSelected;

  static const height = 32.0;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final tab in tabs)
        _RoundTab(
          label: tab.label,
          selected: tab.value == selected,
          onTap: onSelected == null ? null : () => onSelected!(tab.value),
        ),
    ],
  );
}

class _RoundTab extends StatelessWidget {
  const _RoundTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    enabled: onTap != null,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: LdsFocusRing(
      radius: LdsRoundTabs.height / 2,
      child: Material(
        color: selected ? LdsColors.title : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? LdsColors.title : LdsColors.borderStrong,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          hoverColor: selected ? Colors.transparent : LdsColors.canvas,
          child: Container(
            height: LdsRoundTabs.height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            // widthFactor 1: 글자 폭만큼만.
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.white : LdsColors.label,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
