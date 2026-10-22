import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (status) {
      '검토 대기' => (
        const Color(0xFF347BC8),
        const Color(0xFFDCF2FD),
        Icons.schedule,
      ),
      '완료' => (const Color(0xFF4B9138), const Color(0xFFE7F5E1), Icons.check),
      '검토 필요' => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.warning_amber_rounded,
      ),
      _ => (muted, Colors.transparent, Icons.remove),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
