import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../shared/app_font_sizes.dart";
import "../../../shared/widgets/outline_panel.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../../../shared/workspace_colors.dart";
import "../../auth/presentation/gmail_connection_view_model.dart";
import "../domain/work_case.dart";
import "widgets/gmail_read_notice.dart";
import "widgets/queue_group_list.dart";
import "widgets/queue_summary.dart";
import "widgets/work_case_panel.dart";
import "work_queue_view_model.dart";

/// 메인 화면. 사이드바의 품목별 업무 큐에서 고른 업무의 원문과 처리 선택을 보여 줍니다.
///
/// [caseId]는 `/cases/{id}` 주소의 업무입니다. 주소가 선택의 기준이라
/// 새로고침·링크로 같은 업무를 다시 엽니다.
class WorkQueueView extends ConsumerStatefulWidget {
  const WorkQueueView({super.key, this.caseId});

  final String? caseId;

  @override
  ConsumerState<WorkQueueView> createState() => _WorkQueueViewState();
}

class _WorkQueueViewState extends ConsumerState<WorkQueueView> {
  /// 이보다 좁으면 사이드바가 펼쳐지지 않으니 메인에 업무 큐를 직접 보여 줍니다.
  static const _inlineQueueWidth = 480.0;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(WorkQueueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caseId != widget.caseId) _syncSelection();
  }

  /// The sidebar highlight follows the address. Not during build.
  void _syncSelection() => Future.microtask(() {
    if (mounted) {
      ref.read(workQueueViewModelProvider.notifier).select(widget.caseId);
    }
  });

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(workQueueViewModelProvider);
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    final readDenied = ref.watch(gmailCapabilitiesProvider).readDenied;
    final data = value.hasValue ? value.requireValue : null;
    final caseId = widget.caseId;
    final listed = caseId == null
        ? null
        : data?.items.where((workCase) => workCase.id == caseId).firstOrNull;
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
            if (listed != null)
              WorkCasePanel(key: ValueKey(listed.id), workCase: listed)
            // Not in this tab, search, or page: read the case itself.
            else if (caseId != null && (data != null || value.hasError))
              _CaseDetail(caseId: caseId)
            else if (caseId != null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              QueueSummary(
                waitingCount: data?.allWaiting ?? data?.counts.waiting ?? 0,
              ),
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

/// API-02 업무. 목록이 바뀌면 다시 읽어 같은 업무를 보여 줍니다.
class _CaseDetail extends ConsumerWidget {
  const _CaseDetail({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A queue reload (realtime change, a finished step) means this case may
    // have changed too.
    ref.listen(workQueueViewModelProvider, (previous, next) {
      // A selection change keeps the same items; only a reload replaces them.
      final items = next.asData?.value.items;
      if (items != null && items != previous?.asData?.value.items) {
        ref.invalidate(caseDetailProvider(caseId));
      }
    });
    final value = ref.watch(caseDetailProvider(caseId));
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => OutlinePanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 32, color: context.palette.muted),
              const SizedBox(height: 12),
              Text(
                error is WorkQueueFailure ? error.message : "업무를 불러오지 못했습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSizes.bodyLarge,
                  color: context.palette.muted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => ref.invalidate(caseDetailProvider(caseId)),
                    child: const Text("다시 시도"),
                  ),
                  TextButton(
                    onPressed: () => context.go("/"),
                    child: const Text("업무 큐로"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      data: (workCase) =>
          WorkCasePanel(key: ValueKey(workCase.id), workCase: workCase),
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
            color: context.palette.muted,
          ),
          const SizedBox(height: 12),
          Text(
            failed
                ? "업무 큐를 불러오지 못했습니다."
                : "왼쪽 업무 큐에서 품목별 업무를 선택하면\n메일 원문과 첨부파일을 볼 수 있습니다.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              color: context.palette.muted,
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
