import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/work_case.dart";

/// 서버 업무 상태(Waiting·Running·Complete)를 그대로 표시합니다.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.rawCode});

  final WorkCaseStatus status;

  /// 큐 탭에 없는 서버 상태는 받은 값을 그대로 보여 줍니다.
  final String? rawCode;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (status) {
      WorkCaseStatus.waiting => (
        const Color(0xFF2F5E8C),
        const Color(0xFFE6EEF6),
        Icons.schedule,
      ),
      WorkCaseStatus.running => (
        context.palette.ink,
        context.palette.line,
        Icons.hourglass_top,
      ),
      WorkCaseStatus.complete => (
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
        Icons.check,
      ),
      WorkCaseStatus.pending || WorkCaseStatus.confirm => (
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
        Icons.pause_circle_outline,
      ),
      WorkCaseStatus.other => (
        context.palette.muted,
        context.palette.line,
        Icons.remove,
      ),
    };
    final label = status == WorkCaseStatus.other
        ? (rawCode ?? status.label)
        : status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: AppFontSizes.caption, color: color),
          ),
        ],
      ),
    );
  }
}
