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
        Icon(Icons.info_outline, size: 14, color: context.palette.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}
