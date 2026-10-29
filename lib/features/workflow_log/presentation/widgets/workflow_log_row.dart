import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/workflow_log.dart";
import "log_outcome_badge.dart";

/// Time, case, actor, action, short result, and duration.
class WorkflowLogRow extends StatelessWidget {
  const WorkflowLogRow({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final WorkflowLogEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      formatSeoulDateTime(entry.createdAt),
      entry.actor.label,
      entry.eventType.label,
      if (entry.durationMs != null) formatDuration(entry.durationMs!),
    ].join(" · ");
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? blush : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
                bottom: const BorderSide(color: line),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.caseTitle ?? "업무 없음 (접수 단계)",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.w700,
                          color: entry.caseTitle == null ? muted : ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LogOutcomeBadge(entry.outcome),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  entry.summary,
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
