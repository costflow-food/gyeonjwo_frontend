import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/workflow_log.dart";
import "../../domain/workflow_log_filter.dart";
import "log_filter_dropdown.dart";

/// Case search plus period, actor, event, outcome, and send filters.
class WorkflowLogFilters extends StatelessWidget {
  const WorkflowLogFilters({
    super.key,
    required this.filter,
    required this.search,
    required this.onSearch,
    required this.onChanged,
    required this.onReset,
  });

  final WorkflowLogFilter filter;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ValueChanged<WorkflowLogFilter> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final advanced = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LogFilterDropdown<LogActor>(
          label: "역할·노드",
          value: filter.actor,
          options: LogActor.values,
          labelOf: (actor) => actor.label,
          onChanged: (actor) => onChanged(filter.copyWith(actor: () => actor)),
        ),
        LogFilterDropdown<LogEventType>(
          label: "이벤트",
          value: filter.eventType,
          options: LogEventType.values,
          labelOf: (event) => event.label,
          onChanged: (event) =>
              onChanged(filter.copyWith(eventType: () => event)),
        ),
        LogFilterDropdown<LogOutcome>(
          label: "결과",
          value: filter.outcome,
          options: LogOutcome.values,
          labelOf: (outcome) => outcome.label,
          onChanged: (outcome) =>
              onChanged(filter.copyWith(outcome: () => outcome)),
        ),
        LogFilterDropdown<SendPolicy>(
          label: "발송 방식",
          value: filter.sendPolicy,
          options: SendPolicy.values,
          labelOf: (policy) => policy.label,
          onChanged: (policy) =>
              onChanged(filter.copyWith(sendPolicy: () => policy)),
        ),
      ],
    );
    final activeCount = [
      filter.actor,
      filter.eventType,
      filter.outcome,
      filter.sendPolicy,
    ].where((value) => value != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: search,
                onChanged: onSearch,
                style: const TextStyle(fontSize: AppFontSizes.body),
                decoration: const InputDecoration(
                  labelText: '업무',
                  hintText: '업무 제목 또는 ID',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
              ),
            ),
            LogFilterDropdown<LogPeriod>(
              label: '기간',
              value: filter.period,
              options: LogPeriod.values,
              labelOf: (period) => period.label,
              allowAll: false,
              onChanged: (period) =>
                  onChanged(filter.copyWith(period: period ?? LogPeriod.all)),
            ),
            if (!filter.isEmpty)
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text(
                  "필터 초기화",
                  style: TextStyle(fontSize: AppFontSizes.buttonSmall),
                ),
                style: TextButton.styleFrom(foregroundColor: ink),
              ),
          ],
        ),
        ExpansionTile(
          iconColor: ink,
          collapsedIconColor: muted,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: EdgeInsets.zero,
          title: Text(
            activeCount == 0 ? '상세 필터' : '상세 필터 · $activeCount개 적용',
            style: const TextStyle(fontSize: AppFontSizes.body, color: ink),
          ),
          initiallyExpanded: activeCount > 0,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: [advanced],
        ),
      ],
    );
  }
}
