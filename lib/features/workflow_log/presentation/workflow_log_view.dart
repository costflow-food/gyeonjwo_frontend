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
class WorkflowLogView extends ConsumerWidget {
  const WorkflowLogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            builder: (data) =>
                WorkflowLogContent(data: data, viewModel: viewModel),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 32),
            child: NoteLine("관련 업무와 원문에서 근거를 확인하세요."),
          ),
        ],
      ),
    );
  }
}
