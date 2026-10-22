import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';

class QueueTab extends StatelessWidget {
  const QueueTab(this.label, this.count, {super.key});
  final String label, count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: label == '전체' ? ink : line,
            width: label == '전체' ? 2 : 1,
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 12,
                color: label == '전체' ? ink : muted,
                fontWeight: label == '전체' ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            TextSpan(
              text: '  $count',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
