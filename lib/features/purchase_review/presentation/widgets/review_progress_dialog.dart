import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/preview_button.dart";

import "review_progress_step.dart";

/// 실행 후 자동 분석이 거치는 단계. 중간 입력·승인 단계는 두지 않습니다.
const reviewProgressSteps = [
  '요청 정보와 필수 조건 확인',
  '구매 근거와 DB 후보 비교',
  '계약 조건과 비용 영향 정리',
  '검토카드 준비',
];

/// 실행한 요청의 분석 진행을 보여 주는 다이얼로그.
///
/// 진행 상태는 호출한 쪽이 [currentStep]으로 전달합니다. [demo]가 true일 때만
/// 합성 시연 문구를 표시하므로 운영 화면에서는 false로 사용합니다.
class ReviewProgressDialog extends StatelessWidget {
  const ReviewProgressDialog({
    super.key,
    required this.supplier,
    required this.currentStep,
    required this.onClose,
    required this.onGoToQueue,
    this.demo = false,
    this.errorText,
    this.steps = reviewProgressSteps,
  }) : assert(currentStep >= 0 && currentStep <= steps.length);

  final String supplier;

  /// 진행 중인 단계의 0부터 시작하는 순번. [steps] 길이와 같으면 모든 단계 완료입니다.
  final int currentStep;
  final VoidCallback onClose;
  final VoidCallback onGoToQueue;
  final bool demo;

  /// 진행 상태를 받지 못했을 때의 안내. 최종 오류 상태명은 아직 정하지 않았습니다.
  final String? errorText;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 766),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 18, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: const Text(
                            '검토 진행',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          demo ? '디자인 시연 · $supplier 요청' : '$supplier 요청',
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20, color: ink),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.layers_outlined,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '요청의 근거를 모으고 있어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '단가변경 요청부터 거래처 대안까지, 한 번에 살펴봅니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    for (final (index, label) in steps.indexed)
                      ReviewProgressStep(
                        number: index + 1,
                        label: label,
                        state: index < currentStep
                            ? ReviewStepState.done
                            : index == currentStep
                            ? ReviewStepState.active
                            : ReviewStepState.waiting,
                        demo: demo,
                      ),
                    if (errorText != null) ...[
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: ink),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (demo) ...[
                      const SizedBox(height: 22),
                      const Text(
                        '합성 사례의 화면 전환 시연입니다. 실제 AI 분석과 독립 계산 검증을 실행하지 않습니다.',
                        style: TextStyle(
                          fontSize: 10,
                          color: muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: line),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      demo ? '큐로 이동해도 시연은 계속됩니다.' : '큐로 이동해도 분석은 계속됩니다.',
                      style: const TextStyle(fontSize: 10, color: muted),
                    ),
                  ),
                  const SizedBox(width: 16),
                  PreviewButton('업무 큐', onPressed: onGoToQueue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
