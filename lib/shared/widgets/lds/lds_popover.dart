import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';

/// 단추 아래 팝오버: 흰 바탕, 모서리 12, 1px `#E5E7EA`. [alignEnd]면 단추
/// 오른쪽 끝, 아니면 왼쪽 끝에 맞춥니다. 바깥을 누르거나 Esc로 닫습니다.
class LdsPopoverRoute<T> extends PopupRoute<T> {
  LdsPopoverRoute({
    required this.anchor,
    required this.child,
    this.alignEnd = true,
    this.label = '닫기',
  });

  /// 단추의 화면 위치.
  final Rect anchor;
  final Widget child;
  final bool alignEnd;

  /// 바깥(닫기) 영역 이름.
  final String label;

  /// [context]의 위젯 자리.
  static Rect anchorOf(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => CustomSingleChildLayout(
    delegate: _PopoverLayout(anchor, alignEnd: alignEnd),
    child: Material(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LdsRadius.panel),
        side: const BorderSide(color: LdsColors.line),
      ),
      child: child,
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout(this.anchor, {required this.alignEnd});

  final Rect anchor;
  final bool alignEnd;

  static const _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest)
          .deflate(const EdgeInsets.all(_margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (alignEnd ? anchor.right - childSize.width : anchor.left).clamp(
      _margin,
      size.width - childSize.width - _margin,
    );
    final below = anchor.bottom + _margin;
    final y = below + childSize.height <= size.height - _margin
        ? below
        : (size.height - childSize.height - _margin).clamp(_margin, below);
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.alignEnd != alignEnd;
}

