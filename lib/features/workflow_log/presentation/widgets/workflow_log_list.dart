import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/workflow_log.dart";
import "../../domain/workflow_log_state.dart";
import "log_outcome_badge.dart";
import "workflow_log_row.dart";

/// 실행 로그 목록 = 목록 표(9.2): 시각(yyyy.MM.dd HH:mm) · 내용(업무 · 요약 ·
/// 주체·이벤트) · 결과 라벨. 고른 줄은 연한 주황. 좁으면 한 줄씩 쌓습니다.
class WorkflowLogList extends StatelessWidget {
  const WorkflowLogList({
    super.key,
    required this.data,
    required this.onSelect,
    required this.onLoadMore,
    this.showSelection = true,
  });

  /// False on a phone, where the detail opens on its own screen.
  final bool showSelection;

  final WorkflowLogState data;
  final ValueChanged<String> onSelect;
  final VoidCallback onLoadMore;

  /// 이보다 좁으면 표 대신 줄을 쌓습니다.
  static const tableMinWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            data.filter.isEmpty ? "아직 기록된 실행 로그가 없습니다." : "조건과 일치하는 로그가 없습니다.",
            style: const TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (constraints.maxWidth < tableMinWidth)
            for (final entry in data.entries)
              WorkflowLogRow(
                entry: entry,
                selected: showSelection && entry.id == data.selectedId,
                onTap: () => onSelect(entry.id),
              )
          else
            LdsListTable(
              columns: const [
                LdsColumn("시각", flex: 3),
                LdsColumn("내용", flex: 6, alignStart: true),
                LdsColumn("결과", flex: 2),
              ],
              rows: [
                for (final entry in data.entries)
                  LdsListRow(
                    selected: showSelection && entry.id == data.selectedId,
                    onTap: () => onSelect(entry.id),
                    semanticLabel: "${entry.caseLabel}, ${entry.eventLabel}",
                    [
                      Text(
                        formatSeoulDateTime(entry.createdAt),
                        style: const TextStyle(fontSize: 14),
                      ),
                      _Content(entry),
                      entry.outcome == null
                          ? const SizedBox.shrink()
                          : LogOutcomeBadge(entry.outcome!),
                    ],
                  ),
              ],
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
                    : LdsButton(
                        label: "더 보기",
                        variant: LdsButtonVariant.outlinedNeutral,
                        onPressed: onLoadMore,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.entry);

  final WorkflowLogEntry entry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        entry.caseLabel,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: entry.caseId == null ? LdsColors.mutedStrong : LdsColors.ink,
        ),
      ),
      if (entry.summary.isNotEmpty)
        Text(
          entry.summary,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: LdsColors.title,
          ),
        ),
      Text(
        logMeta(entry, withTime: false),
        style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
      ),
    ],
  );
}
