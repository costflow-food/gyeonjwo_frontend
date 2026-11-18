import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds_metrics.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../../review_progress/presentation/review_progress_view.dart";
import "../../../supplier/presentation/supplier_register_dialog.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";

/// 이 업무에 볼 메일 초안이 있는지. 견적 요청을 준비한 뒤의 단계(발송 설정
/// 멈춤 포함)는 단계만으로 알고, 발송 실패(FAILED)나 회신이 연결된 뒤는
/// API-16에 묻습니다.
bool caseHasMailDrafts(WidgetRef ref, WorkCase workCase) {
  final progress = workCase.stopped
      ? ref.watch(caseProgressProvider(workCase.id)).asData?.value
      : null;
  final hold = progress?.hold ?? workCase.hold;
  final draftsByStep =
      ProcessingStep.withDrafts.contains(workCase.processingStep) ||
      (hold?.code ?? progress?.errorCode) == "SEND_POLICY_REQUIRED";
  final mayHaveDrafts =
      workCase.processingStep == "FAILED" || workCase.inputRevision > 1;
  return draftsByStep ||
      (mayHaveDrafts &&
          (ref.watch(caseHasDraftsProvider(workCase.id)).value ?? false));
}

class CaseStepStatus extends ConsumerStatefulWidget {
  const CaseStepStatus({
    super.key,
    required this.workCase,
    this.showDraftButton = true,
  });

  final WorkCase workCase;

  /// false면 '메일 초안 보기'를 두지 않습니다(넓은 화면은 상세 머리에 있음).
  final bool showDraftButton;

  @override
  ConsumerState<CaseStepStatus> createState() => _CaseStepStatusState();
}

class _CaseStepStatusState extends ConsumerState<CaseStepStatus> {
  bool _busy = false;
  String? _error;

  Future<void> _resume() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    // The panel rebuilds as the step changes; keep a context that stays.
    final navigator = Navigator.of(context, rootNavigator: true).context;
    try {
      await viewModel.resume(widget.workCase);
      if (mounted) setState(() => _busy = false);
      if (navigator.mounted) {
        await showReviewProgressDialog(
          navigator,
          caseId: widget.workCase.id,
          title: widget.workCase.title,
        );
      }
    } on WorkQueueFailure catch (failure) {
      if (!mounted) return;
      // A retryable failure may still have gone through; read it again.
      if (failure.caseChanged || failure.retryable) viewModel.refresh();
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."
            : failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workCase = widget.workCase;
    // The list already carries hold; API-03 gives the latest one.
    final progress = workCase.stopped
        ? ref.watch(caseProgressProvider(workCase.id)).asData?.value
        : null;
    final hold = progress?.hold ?? workCase.hold;
    final reason =
        stopReasonMessage(hold, progress?.errorCode) ??
        (workCase.atCandidates
            ? workCase.disabledMessage(WorkCaseAction.selectCandidates)
            : null);
    final hasDrafts =
        widget.showDraftButton && caseHasMailDrafts(ref, workCase);
    final needsSupplier =
        workCase.stopped &&
        supplierMissingStopCodes.contains(hold?.code ?? progress?.errorCode);
    final canResume = workCase.can(WorkCaseAction.resume);
    final resumeBlocked = workCase.disabledMessage(WorkCaseAction.resume);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LdsColors.canvas,
            borderRadius: BorderRadius.circular(LdsRadius.table),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                workCase.stopped
                    ? Icons.pause_circle_outline
                    : Icons.info_outline,
                size: 18,
                color: workCase.stopped ? danger : context.palette.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workCase.stepMessage.isEmpty
                          ? "검토가 진행되고 있습니다."
                          : workCase.stepMessage,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: reason == null
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                    if (workCase.replySummary case final replies?
                        when replies.visible) ...[
                      const SizedBox(height: 6),
                      Text(
                        replies.label,
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                    if (reason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: AppFontSizes.body,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasDrafts) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () =>
                    showMailDraftDialog(context, caseId: workCase.id),
                style: WorkspaceButtonStyles.outlined(context),
                icon: const Icon(Icons.mail_outline, size: 16),
                label: const Text("메일 초안 보기"),
              ),
            ),
          ),
        ],
        if (needsSupplier) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => showSupplierRegisterDialog(context),
                style: WorkspaceButtonStyles.outlined(context),
                icon: const Icon(Icons.store_outlined, size: 16),
                label: const Text("거래처 등록"),
              ),
            ),
          ),
        ],
        if (canResume || resumeBlocked != null) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: canResume && !_busy ? _resume : null,
                style: WorkspaceButtonStyles.filled(context),
                icon: const Icon(Icons.replay, size: 16),
                label: Text(workCase.resumeReason.buttonLabel),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canResume ? workCase.resumeReason.help : resumeBlocked!,
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              color: context.palette.muted,
              height: 1.5,
            ),
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(minHeight: 2, color: context.palette.accent),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(fontSize: AppFontSizes.body, color: danger),
          ),
        ],
      ],
    );
  }
}
