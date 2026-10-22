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
        backgroundColor: filled ? ink : Colors.transparent,
        foregroundColor: filled ? Colors.white : ink,
        side: BorderSide(color: filled ? ink : const Color(0xFFAFB3BA)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
