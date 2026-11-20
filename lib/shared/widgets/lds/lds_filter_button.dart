import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_button.dart';
import 'lds_focus_ring.dart';
import 'lds_metrics.dart';
import 'lds_popover.dart';
import 'lds_tag.dart';
import 'lds_text_field.dart';

/// 필터 선택지 하나: 값 + 건수.
class LdsFilterOption {
  const LdsFilterOption(this.value, this.count);

  final String value;
  final int count;
}

/// 필터 단추 `[품목 ▾]` (`docs/design-ssot.md` 7.12).
///
/// 누르면 창: 검색칸(선택지 5개 이하면 생략) + [caption](예: '최근 거래순')
/// + 체크 목록(줄 44, 건수 `#8A95A0`, 최대 264 후 스크롤) + 오른쪽 '선택 해제'.
/// 여러 개 선택, 고르는 즉시 [onChanged]. 창이 열린 동안, 또 고른 값이 있으면
/// 진한 테두리 `#333D4B`. 고른 값이 있으면 개수 배지(4.2 dark).
class LdsFilterButton extends StatefulWidget {
  const LdsFilterButton({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.caption,
    this.padding = const EdgeInsets.only(left: 12, right: 8),
  });

  final String label;

  /// 버튼 내부 여백. 좁은 필터 줄에서는 줄여서 사용합니다.
  final EdgeInsetsGeometry padding;

  /// 목록 위 13px `#8A95A0` 안내(예: '최근 거래순').
  final String? caption;

  /// 보여 줄 순서대로(예: 최근 거래순).
  final List<LdsFilterOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<LdsFilterButton> createState() => _LdsFilterButtonState();
}

class _LdsFilterButtonState extends State<LdsFilterButton> {
  final _focus = FocusNode(debugLabel: 'filter button');
  bool _open = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    setState(() => _open = true);
    await Navigator.of(context).push(
      LdsPopoverRoute<void>(
        anchor: LdsPopoverRoute.anchorOf(context),
        alignEnd: false,
        label: '${widget.label} 필터 닫기',
        child: _FilterMenu(
          label: widget.label,
          caption: widget.caption,
          options: widget.options,
          initial: widget.selected,
          onChanged: widget.onChanged,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.selected.length;
    final active = count > 0;
    final radius = BorderRadius.circular(LdsRadius.button);
    return Semantics(
      button: true,
      label: active ? '${widget.label} 필터, $count개 선택됨' : '${widget.label} 필터',
      excludeSemantics: true,
      onTap: _show,
      child: LdsFocusRing(
        radius: LdsRadius.button,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: active || _open ? LdsColors.title : LdsColors.borderStrong,
            ),
          ),
          child: InkWell(
            focusNode: _focus,
            onTap: _show,
            borderRadius: radius,
            hoverColor: LdsColors.canvas,
            child: Container(
              height: 36,
              padding: widget.padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: LdsText.control,
                      height: 1.2,
                      letterSpacing: -.3,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: LdsColors.ink,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    LdsBadge(count, tone: LdsBadgeTone.dark),
                  ],
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

/// '맞는 품목이 없어요' / '맞는 거래처가 없어요'. 한글로 끝나지 않으면
/// '맞는 항목이 없어요'.
String _noMatchText(String label) {
  final last = label.isEmpty ? 0 : label.codeUnitAt(label.length - 1);
  if (last < 0xAC00 || last > 0xD7A3) return '맞는 항목이 없어요';
  final particle = (last - 0xAC00) % 28 == 0 ? '가' : '이';
  return '맞는 $label$particle 없어요';
}

class _FilterMenu extends StatefulWidget {
  const _FilterMenu({
    required this.label,
    required this.caption,
    required this.options,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String? caption;
  final List<LdsFilterOption> options;
  final Set<String> initial;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<_FilterMenu> {
  late Set<String> _selected = {...widget.initial};
  String _query = '';

  static const _width = 280.0;
  static const _listMax = 264.0;

  void _set(Set<String> next) {
    setState(() => _selected = next);
    widget.onChanged(next);
  }

  void _toggle(String value) => _set(
    _selected.contains(value)
        ? ({..._selected}..remove(value))
        : {..._selected, value},
  );

  @override
  Widget build(BuildContext context) {
    final searchable = widget.options.length > 5;
    final shown = [
      for (final option in widget.options)
        if (_query.isEmpty ||
            option.value.toLowerCase().contains(_query.toLowerCase()))
          option,
    ];
    return SizedBox(
      width: _width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: LdsTextField(
                  autofocus: true,
                  prefixIcon: Icons.search,
                  hintText: '${widget.label} 검색',
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
            if (widget.caption case final caption?)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdsColors.outline,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _listMax),
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _noMatchText(widget.label),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: LdsColors.muted,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final (index, option) in shown.indexed)
                          _CheckRow(
                            option: option,
                            checked: _selected.contains(option.value),
                            autofocus: !searchable && index == 0,
                            onTap: () => _toggle(option.value),
                          ),
                      ],
                    ),
            ),
            const Divider(height: 17, color: LdsColors.line),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LdsButton(
                  label: '선택 해제',
                  size: LdsButtonSize.small,
                  variant: LdsButtonVariant.ghostNeutral,
                  onPressed: _selected.isEmpty ? null : () => _set({}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.option,
    required this.checked,
    required this.autofocus,
    required this.onTap,
  });

  final LdsFilterOption option;
  final bool checked;
  final bool autofocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: checked,
    label: '${option.value}, ${option.count}건',
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      autofocus: autofocus,
      onTap: onTap,
      hoverColor: LdsColors.canvas,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: checked ? LdsColors.primary : LdsColors.borderStrong,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  letterSpacing: -.3,
                  color: LdsColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${option.count}건',
              style: const TextStyle(
                fontSize: 13,
                color: LdsColors.outline,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 고른 필터 값 태그(× 빼기). 필터 바 아래에 둡니다(7.12).
class LdsRemovableTag extends StatelessWidget {
  const LdsRemovableTag(this.label, {super.key, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.only(left: 10, right: 4),
    decoration: BoxDecoration(
      color: LdsColors.badgeNeutralBg,
      borderRadius: BorderRadius.circular(LdsRadius.button),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: LdsColors.title),
        ),
        const SizedBox(width: 2),
        Semantics(
          button: true,
          label: '$label 빼기',
          excludeSemantics: true,
          onTap: onRemove,
          child: LdsFocusRing(
            radius: LdsRadius.button,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(LdsRadius.button),
              child: const SizedBox.square(
                dimension: 24,
                child: Icon(Icons.close, size: 16, color: LdsColors.label),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
