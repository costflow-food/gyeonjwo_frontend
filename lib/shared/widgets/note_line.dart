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
        // 첫 줄 높이(13 × 1.65 ≈ 21.5)의 가운데에 아이콘(14)을 맞춥니다.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: context.palette.muted,
          ),
        ),
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
