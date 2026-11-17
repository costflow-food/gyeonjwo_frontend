import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../lds_colors.dart';

enum LdsToggleSize {
  /// 트랙 32×20, 손잡이 16.
  medium(width: 32, height: 20, knob: 16),

  /// 트랙 28×16, 손잡이 12.
  small(width: 28, height: 16, knob: 12);

  const LdsToggleSize({
    required this.width,
    required this.height,
    required this.knob,
  });

  final double width, height, knob;
}

/// 토글 — LIKELION Toggle (`docs/design-ssot.md` 5장).
///
/// 여백 2, 꺼짐 `#E5E7EA`, 켜짐 `#FF6000`, 손잡이 흰색 + 그림자, 0.2초 이동.
/// 비활성: 꺼짐 `#F3F4F6`, 켜짐 `rgba(255,96,0,.24)`. [onChanged]가 null이면 비활성.
class LdsToggle extends StatelessWidget {
  const LdsToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = LdsToggleSize.medium,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final LdsToggleSize size;
  final String? semanticLabel;

  static const _onDisabled = Color(0x3DFF6000);

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final track = switch ((value, enabled)) {
      (true, true) => LdsColors.primary,
      (false, true) => LdsColors.line,
      (true, false) => _onDisabled,
      (false, false) => LdsColors.lineSoft,
    };
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: _Pressable(
        enabled: enabled,
        onActivate: () => onChanged?.call(!value),
        builder: (focused) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size.width,
          height: size.height,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(size.height / 2),
            boxShadow: focused ? _focusRing : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: size.knob,
              height: size.knob,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
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

/// 라디오 — LIKELION RadioButton (`docs/design-ssot.md` 6.2).
///
/// 아이콘 24px, 꺼짐 `#D1D6DC`, 켜짐 `#FF6000`, 포커스 시 주황 2px 외곽선을 2px 띄워 그립니다.
class LdsRadio<T> extends StatelessWidget {
  const LdsRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final enabled = onChanged != null;
    final ring = !enabled
        ? LdsColors.line
        : selected
        ? LdsColors.primary
        : LdsColors.borderStrong;
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      label: semanticLabel,
      child: _Pressable(
        enabled: enabled,
        onActivate: () => onChanged?.call(value),
        builder: (focused) => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: focused ? _focusRing : null,
          ),
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: selected ? 6 : 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 2px 띄운 주황 2px 외곽선: 주황 4px을 먼저 깔고 그 위에 흰 2px을 덮습니다.
const _focusRing = [
  BoxShadow(color: LdsColors.primary, spreadRadius: 4),
  BoxShadow(color: Colors.white, spreadRadius: 2),
];

/// 눌러서·키보드(스페이스·엔터)로 켜고 끄는 영역. 포커스 상태를 [builder]에 넘깁니다.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.enabled,
    required this.onActivate,
    required this.builder,
  });

  final bool enabled;
  final VoidCallback onActivate;
  final Widget Function(bool focused) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: widget.enabled,
    mouseCursor: widget.enabled
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic,
    onShowFocusHighlight: (value) => setState(() => _focused = value),
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          widget.onActivate();
          return null;
        },
      ),
    },
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onActivate : null,
      child: widget.builder(_focused && widget.enabled),
    ),
  );
}
