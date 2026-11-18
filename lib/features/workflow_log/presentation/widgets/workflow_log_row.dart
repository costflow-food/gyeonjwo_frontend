import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../domain/workflow_log.dart";
import "log_outcome_badge.dart";

/// 휴대폰 목록의 한 줄(폭이 좁아 표 대신): 업무 · 결과 라벨 · 요약 · 시각.
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
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LdsColors.lineSoft)),
          ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: entry.caseId == null
                            ? LdsColors.mutedStrong
                            : LdsColors.ink,
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
                const SizedBox(height: 4),
                Text(
                  entry.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: LdsColors.title,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                logMeta(entry),
                style: const TextStyle(
                  fontSize: 13,
                  color: LdsColors.mutedStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 시각 · 주체 · 이벤트 · 소요 시간.
String logMeta(WorkflowLogEntry entry, {bool withTime = true}) => [
  if (withTime) formatSeoulDateTime(entry.createdAt),
  entry.actor?.label ?? entry.actorLabel,
  entry.eventLabel,
  if (entry.durationMs != null) formatDuration(entry.durationMs!),
].join(" · ");
