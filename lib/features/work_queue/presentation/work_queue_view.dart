import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/app_font_sizes.dart";
import "../../../shared/widgets/outline_panel.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../../../shared/workspace_colors.dart";
import "../../auth/presentation/gmail_connection_view_model.dart";
import "widgets/gmail_read_notice.dart";
import "widgets/queue_group_list.dart";
import "widgets/queue_summary.dart";
import "widgets/work_case_panel.dart";
import "work_queue_view_model.dart";

/// 메인 화면. 사이드바의 품목별 업무 큐에서 고른 업무의 원문과 처리 선택을 보여 줍니다.
class WorkQueueView extends ConsumerWidget {
  const WorkQueueView({super.key});

  /// 이보다 좁으면 사이드바가 펼쳐지지 않으니 메인에 업무 큐를 직접 보여 줍니다.
  static const _inlineQueueWidth = 480.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(workQueueViewModelProvider);
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    final readDenied = ref.watch(gmailCapabilitiesProvider).readDenied;
    final data = value.hasValue ? value.requireValue : null;
    final selected = data?.selected;
    return WorkspaceShell(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outside the list state so it shows even when loading fails.
            if (readDenied) ...[
              const GmailReadNotice(),
              const SizedBox(height: 16),
            ],
            if (selected != null)
              WorkCasePanel(key: ValueKey(selected.id), workCase: selected)
            else ...[
              QueueSummary(waitingCount: data?.counts.waiting ?? 0),
              const SizedBox(height: 24),
              if (constraints.maxWidth < _inlineQueueWidth)
                const OutlinePanel(
                  padding: EdgeInsets.all(12),
                  child: QueueGroupList(shrinkWrap: true),
                )
              else
                _Guidance(
                  failed: value.hasError && data == null,
                  onRetry: viewModel.refresh,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => OutlinePanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            failed ? Icons.error_outline : Icons.mark_email_read_outlined,
            size: 32,
            color: muted,
          ),
          const SizedBox(height: 12),
          Text(
            failed
                ? "업무 큐를 불러오지 못했어요."
                : "왼쪽 업무 큐에서 품목별 업무를 선택하면\n메일 원문과 첨부파일을 볼 수 있어요.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              color: muted,
              height: 1.7,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("다시 시도")),
          ],
        ],
      ),
    ),
  );
}
