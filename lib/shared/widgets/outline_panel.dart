import 'package:flutter/material.dart';

import '../workspace_colors.dart';

class OutlinePanel extends StatelessWidget {
  const OutlinePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.palette.ink.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
