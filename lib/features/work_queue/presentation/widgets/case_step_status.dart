import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
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
  /// API-03 error는 코드만 옵니다. 서버가 문구를 보내기 전까지 hold와 같은 문구를 씁니다.
  static const _errorMessages = {
    "NO_SUITABLE_CANDIDATES": "요청 조건에 맞는 거래처 후보를 찾지 못했어요.",
    "SEND_POLICY_REQUIRED": "견적 요청에 필요한 발송 설정을 확인해야 해요.",
  };

  bool _busy = false;
  String? _error;

  Future<void> _resume() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    try {
      await viewModel.resume(widget.workCase);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text("다시 추출을 접수했어요. 요청 정보 확인부터 다시 진행해요."),
        ),
      );
      if (mounted) setState(() => _busy = false);
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
    // The list already carries hold; API-03 also gives the NEEDS_INFO code.
    final progress = workCase.stopped
        ? ref.watch(caseProgressProvider(workCase.id)).asData?.value
        : null;
    final hold = progress?.hold ?? workCase.hold;
    final reason =
        hold?.message ??
        _errorMessages[progress?.errorCode] ??
        (workCase.atCandidates
            ? workCase.disabledMessage(WorkCaseAction.selectCandidates)
            : null);
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
                color: workCase.stopped ? accent : muted,
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
                label: const Text("다시 추출"),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canResume
                ? "보류 사유를 확인했다면 요청 정보 확인부터 다시 실행해요."
                : resumeBlocked!,
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
            style: const TextStyle(fontSize: AppFontSizes.body, color: accent),
          ),
        ],
      ],
    );
  }
}
