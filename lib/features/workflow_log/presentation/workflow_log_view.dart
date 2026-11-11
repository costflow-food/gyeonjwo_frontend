import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/note_line.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/workflow_log_state.dart";
import "widgets/workflow_log_content.dart";
import "widgets/workflow_log_detail.dart";
import "widgets/workflow_log_header.dart";
import "workflow_log_view_model.dart";

class WorkflowLogView extends ConsumerWidget {
  const WorkflowLogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(workflowLogViewModelProvider);
    final viewModel = ref.read(workflowLogViewModelProvider.notifier);
    if (isCompactLayout(context)) {
      return MobileTabScaffold(
        title: "로그",
        actions: [
          IconButton(
            tooltip: "새로고침",
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AsyncContent<WorkflowLogState>(
              value: value,
              onRetry: viewModel.refresh,
              builder: (data) => WorkflowLogContent(
                data: data,
                viewModel: viewModel,
                onOpenDetail: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _LogDetailPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
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
            child: NoteLine("관련 업무와 원문에서 근거를 확인하십시오."),
          ),
        ],
      ),
    );
  }
}

/// Phone: the selected log on its own screen.
class _LogDetailPage extends ConsumerWidget {
  const _LogDetailPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workflowLogViewModelProvider).value;
    final viewModel = ref.read(workflowLogViewModelProvider.notifier);
    return MobilePageScaffold(
      title: "로그 상세",
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: WorkflowLogDetail(
          entry: data?.selected,
          caseFiltered: data?.filter.caseId != null,
          onFilterCase: (caseId, {caseTitle}) {
            viewModel.filterCase(caseId, caseTitle: caseTitle);
            // The filter shows on the list.
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
