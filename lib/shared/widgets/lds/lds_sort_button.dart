import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_focus_ring.dart';
import 'lds_metrics.dart';
import 'lds_popover.dart';

/// 정렬 선택지 하나. [enabled]가 false면 회색으로 보이고 고를 수 없습니다.
class LdsSortChoice<T> {
  const LdsSortChoice(this.value, this.label, {this.enabled = true});

  final T value;
  final String label;
  final bool enabled;
}

/// 목록 위 오른쪽 정렬 선택 '최신순 ▾' (Invoices·Suppliers 공용).
///
/// 필터 단추([LdsFilterButton])와 같은 모양: 흰 바탕 · 테두리 `#D1D6DC`
/// (열려 있으면 `#333D4B`) · 높이 36 · 글자 15 `#191F28` · 오른쪽 ▾.
/// 누르면 선택지 창(줄 44)이 열리고, 지금 정렬은 굵게 + 주황 체크입니다.
class LdsSortButton<T> extends StatefulWidget {
  const LdsSortButton({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  final List<LdsSortChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<LdsSortButton<T>> createState() => _LdsSortButtonState<T>();
}

class _LdsSortButtonState<T> extends State<LdsSortButton<T>> {
  final _focus = FocusNode(debugLabel: "sort button");
  bool _open = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  LdsSortChoice<T> get _current => widget.choices.firstWhere(
    (choice) => choice.value == widget.selected,
    orElse: () => widget.choices.first,
  );

  Future<void> _show() async {
    setState(() => _open = true);
    final picked = await Navigator.of(context).push(
      LdsPopoverRoute<LdsSortChoice<T>>(
        anchor: LdsPopoverRoute.anchorOf(context),
        label: "정렬 닫기",
        child: _SortMenu<T>(choices: widget.choices, current: _current),
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    _focus.requestFocus();
    if (picked != null && picked.value != widget.selected) {
      widget.onChanged(picked.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _current.label;
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

/// 정렬 창: 선택지마다 줄 44, 지금 정렬은 굵게 + 주황 체크.
class _SortMenu<T> extends StatelessWidget {
  const _SortMenu({required this.choices, required this.current});

  final List<LdsSortChoice<T>> choices;
  final LdsSortChoice<T> current;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final choice in choices)
            _choiceRow(
              context,
              choice,
              selected: choice.value == current.value,
            ),
        ],
      ),
    ),
  );

  Widget _choiceRow(
    BuildContext context,
    LdsSortChoice<T> choice, {
    required bool selected,
  }) {
    final enabled = choice.enabled;
    void pick() => Navigator.of(context).pop(choice);
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      label: "${choice.label} 정렬",
      excludeSemantics: true,
      onTap: enabled ? pick : null,
      child: InkWell(
        autofocus: selected,
        onTap: enabled ? pick : null,
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
                    color: enabled ? LdsColors.ink : LdsColors.disabled,
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
