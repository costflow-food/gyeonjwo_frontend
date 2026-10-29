import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/workflow_log_state.dart";
import "workflow_log_row.dart";

class WorkflowLogList extends StatelessWidget {
  const WorkflowLogList({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onLoadMore,
  });

  final WorkflowLogState data;
  final ValueChanged<String> onSelect;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            data.filter.isEmpty
                ? "아직 기록된 실행 로그가 없습니다."
                : "조건과 일치하는 로그가 없습니다.",
            style: const TextStyle(fontSize: AppFontSizes.body, color: muted),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in data.entries)
          WorkflowLogRow(
            entry: entry,
            selected: entry.id == data.selectedId,
            onTap: () => onSelect(entry.id),
          ),
        if (data.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: data.isLoadingMore
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: onLoadMore,
                      child: const Text(
                        "더 보기",
                        style: TextStyle(fontSize: AppFontSizes.button),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
