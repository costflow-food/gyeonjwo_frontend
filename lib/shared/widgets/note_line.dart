import 'package:flutter/material.dart';

import '../workspace_colors.dart';

class NoteLine extends StatelessWidget {
  const NoteLine(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: muted, fontSize: 11, height: 1.65),
          ),
        ),
      ],
    );
  }
}
