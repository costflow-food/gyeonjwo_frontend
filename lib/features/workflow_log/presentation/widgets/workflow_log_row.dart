import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/workflow_log.dart";
import "log_outcome_badge.dart";

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
      entry.actor?.label ?? entry.actorLabel,
      entry.eventLabel,
      if (entry.durationMs != null) formatDuration(entry.durationMs!),
    ].join(" · ");
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? context.palette.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selected
              ? BorderSide(color: context.palette.accentText, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.caseLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.w700,
                          color: entry.caseId == null
                              ? context.palette.muted
                              : context.palette.ink,
                        ),
                      ),
                    ),
                    if (entry.outcome != null) ...[
                      const SizedBox(width: 8),
                      LogOutcomeBadge(entry.outcome!),
                    ],
                  ],
                ),
                if (entry.summary.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    entry.summary,
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  meta,
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: context.palette.muted,
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
