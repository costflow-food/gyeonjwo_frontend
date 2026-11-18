import 'package:flutter/material.dart';

import '../../lds_colors.dart';

/// 키보드 포커스 외곽선: 주황 2px, 2px 띄움 (`docs/design-ssot.md` 7.8.4).
///
/// [child] 안의 위젯(InkWell 등)이 키보드로 포커스를 받으면 바깥에 그립니다.
/// 마우스·터치로 누를 때는 그리지 않습니다.
class LdsFocusRing extends StatefulWidget {
  const LdsFocusRing({super.key, required this.child, this.radius = 8});

  final Widget child;

  /// [child]의 모서리. 외곽선은 4 더 둥급니다.
  final double radius;

  @override
  State<LdsFocusRing> createState() => _LdsFocusRingState();
}

class _LdsFocusRingState extends State<LdsFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (focused) => setState(
      () => _focused =
          focused &&
          FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_focused)
          Positioned(
            left: -4,
            top: -4,
            right: -4,
            bottom: -4,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: LdsColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(widget.radius + 4),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
