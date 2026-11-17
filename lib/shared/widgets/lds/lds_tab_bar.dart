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
  });

  final List<LdsTabItem<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: LdsColors.line)),
    ),
    child: SingleChildScrollView(
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
  const _Tab({required this.tab, required this.selected, required this.onTap});

  final LdsTabItem<T> tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = tab.count;
    return Semantics(
      selected: selected,
      button: true,
      label: count == null ? tab.label : '${tab.label} $count건',
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
            height: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? LdsColors.ink : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
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
            ),
          ),
        ),
      ),
    );
  }
}
