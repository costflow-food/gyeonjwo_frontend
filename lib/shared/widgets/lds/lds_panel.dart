import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';

/// 흰 패널: 1px `#E5E7EA`, 모서리 12 (`docs/design-ssot.md` 1장).
/// 그림자·입체 테두리는 쓰지 않습니다.
class LdsPanel extends StatelessWidget {
  const LdsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.panel),
    ),
    child: child,
  );
}
