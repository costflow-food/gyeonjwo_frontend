import 'package:flutter/material.dart';

import '../workspace_colors.dart';

class PreviewButton extends StatelessWidget {
  const PreviewButton(
    this.label, {
    super.key,
    this.icon,
    this.onPressed,
    this.filled = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: filled ? accent : Colors.transparent,
        foregroundColor: filled ? Colors.white : accent,
        side: const BorderSide(color: accent),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        minimumSize: const Size(0, 40),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 7)],
          Text(label),
        ],
      ),
    );
  }
}
