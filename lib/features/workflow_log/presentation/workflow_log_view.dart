import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/note_line.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/workflow_log_state.dart";
import "widgets/workflow_log_content.dart";
import "widgets/workflow_log_header.dart";
import "workflow_log_view_model.dart";

/// SCR-010 실행 로그. Case, role, node, tool, send, and settings history.
class WorkflowLogView extends ConsumerStatefulWidget {
  const WorkflowLogView({super.key});

  @override
  ConsumerState<WorkflowLogView> createState() => _WorkflowLogViewState();
}

class _WorkflowLogViewState extends ConsumerState<WorkflowLogView> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    // Restore the filter kept by the ViewModel when returning to this route.
    _search = TextEditingController(
      text:
          ref
              .read(workflowLogViewModelProvider)
              .asData
              ?.value
              .filter
              .caseQuery ??
          "",
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetFilter() {
    _search.clear();
    ref.read(workflowLogViewModelProvider.notifier).resetFilter();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(workflowLogViewModelProvider);
    final viewModel = ref.read(workflowLogViewModelProvider.notifier);
    return WorkspaceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkflowLogHeader(onRefresh: viewModel.refresh),
          const SizedBox(height: 24),
          AsyncContent<WorkflowLogState>(
            value: value,
            onRetry: viewModel.refresh,
            builder: (data) => WorkflowLogContent(
              data: data,
              search: _search,
              viewModel: viewModel,
              onReset: _resetFilter,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 32),
            child: NoteLine("시연 데이터입니다. 관련 업무와 원문에서 근거를 확인하세요."),
          ),
        ],
      ),
    );
  }
}
