import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../domain/workflow_log_filter.dart";

/// The case the list is narrowed to; removing the chip shows every case.
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
      child: InputChip(
        avatar: const Icon(Icons.work_outline, size: 16),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            "업무: ${filter.caseTitle ?? filter.caseId}",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: AppFontSizes.body),
          ),
        ),
        tooltip: "모든 업무의 로그 보기",
        onDeleted: onClearCase,
      ),
    );
  }
}
