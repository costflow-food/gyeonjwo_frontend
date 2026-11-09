import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../../review_progress/presentation/review_progress_view.dart";
import "../../../server_status/presentation/server_status_view_model.dart";
import "../../../supplier/presentation/supplier_register_dialog.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";

/// 이미 실행한 업무의 현재 단계. 멈춘 업무는 서버가 알려 준 이유와,
/// 서버가 허용하면 '다시 추출'(API-07)을 보여 줍니다.
class CaseStepStatus extends ConsumerStatefulWidget {
  const CaseStepStatus({super.key, required this.workCase});

  final WorkCase workCase;

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
      if (failure.caseChanged) viewModel.refresh();
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요."
            : failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요.";
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
    // Drafts exist once RFQs were prepared, including a send-setting stop.
    // A send failure (FAILED) or any step after a linked reply may also have
    // drafts, but the step alone cannot tell, so ask API-16 there.
    final draftsByStep =
        ProcessingStep.withDrafts.contains(workCase.processingStep) ||
        (hold?.code ?? progress?.errorCode) == "SEND_POLICY_REQUIRED";
    final mayHaveDrafts =
        workCase.processingStep == "FAILED" || workCase.inputRevision > 1;
    final hasDrafts =
        draftsByStep ||
        (mayHaveDrafts &&
            (ref.watch(caseHasDraftsProvider(workCase.id)).value ?? false));
    // X-15: a linked reply waits here while the server cannot review it.
    final server = ref.watch(serverStatusViewModelProvider).asData?.value;
    final replyReviewBlocked =
        isReplyExtraction(workCase.processingStep, workCase.inputRevision) &&
        (server?.replyReviewBlocked ?? false);
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
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                workCase.stopped
                    ? Icons.pause_circle_outline
                    : Icons.info_outline,
                size: 18,
                color: workCase.stopped ? danger : muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workCase.stepMessage.isEmpty
                          ? "검토가 진행되고 있어요."
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
                        style: const TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: muted,
                        ),
                      ),
                    ],
                    if (replyReviewBlocked) ...[
                      const SizedBox(height: 6),
                      const Text(
                        "서버의 회신 검토 기능이 아직 준비되지 않아 "
                        "이 회신은 검토로 넘어가지 못하고 있어요.",
                        style: TextStyle(
                          fontSize: AppFontSizes.body,
                          color: danger,
                          height: 1.6,
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
                style: WorkspaceButtonStyles.outlined,
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
                style: WorkspaceButtonStyles.outlined,
                icon: const Icon(Icons.store_outlined, size: 16),
                label: const Text("거래처 등록"),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "요청 품목을 취급하는 거래처를 등록하면 후보로 찾을 수 있어요.",
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              color: muted,
              height: 1.5,
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
                style: WorkspaceButtonStyles.filled,
                icon: const Icon(Icons.replay, size: 16),
                label: Text(workCase.resumeReason.buttonLabel),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canResume ? workCase.resumeReason.help : resumeBlocked!,
            style: const TextStyle(
              fontSize: AppFontSizes.secondary,
              color: muted,
              height: 1.5,
            ),
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2, color: accent),
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
