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
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
