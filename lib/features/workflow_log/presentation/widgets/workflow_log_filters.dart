import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../domain/workflow_log_filter.dart";

/// 업무로 거른 목록: 업무 이름 칩(높이 32, 모서리 16) + 지우기.
class WorkflowLogFilters extends StatelessWidget {
  const WorkflowLogFilters({
    super.key,
    required this.filter,
    required this.onClearCase,
  });

  final WorkflowLogFilter filter;
  final VoidCallback onClearCase;

  @override
  Widget build(BuildContext context) {
    if (filter.caseId == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LdsColors.borderStrong),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline, size: 16, color: LdsColors.title),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                "업무: ${filter.caseTitle ?? filter.caseId}",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: LdsColors.ink),
              ),
            ),
            IconButton(
              tooltip: "모든 업무의 이력 보기",
              onPressed: onClearCase,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, color: LdsColors.title),
            ),
          ],
        ),
      ),
    );
  }
}
