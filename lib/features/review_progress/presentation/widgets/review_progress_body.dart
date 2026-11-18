import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/review_phase.dart";
import "../../../../shared/widgets/workflow_step_icon.dart";
import "../../domain/review_progress_repository.dart";
import "../../domain/review_progress_state.dart";

/// 검토 진행 창 본문 (`docs/design-ssot.md` 8.2): 지금 단계 요약 → 할 일 안내
/// → 진행 단계(가로) → (자동 확인 멈춤 안내).
class ReviewProgressBody extends StatelessWidget {
  const ReviewProgressBody({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final ReviewProgress state;
  final VoidCallback onRetry;

  /// 진행 단계 막대의 지금 단계: 처리 중·멈춘 단계, 아니면 마친 단계 다음
  /// (모두 마쳤으면 단계 수). 아무 단계도 시작하지 않았으면 null.
  static int? currentIndex(List<StageState> stages) {
    final active = stages.indexWhere(
      (stage) => stage == StageState.running || stage == StageState.stopped,
    );
    if (active >= 0) return active;
    final done = stages.where((stage) => stage == StageState.done).length;
    return done == 0 ? null : done;
  }

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;
    final stages = state.stages;
    final current = currentIndex(stages);
    final failure = state.refreshFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(stages: stages, current: current),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: outcome == null
              ? const LdsNotice(
                  tone: LdsNoticeTone.success,
                  message: "지금은 하실 일이 없습니다. 검토는 서버에서 이어집니다.",
                )
              : LdsNotice(
                  tone: switch (outcome) {
                    ReviewOutcome(stopped: true) => LdsNoticeTone.error,
                    ReviewOutcome.reviewReady => LdsNoticeTone.success,
                    ReviewOutcome.chooseCandidates ||
                    ReviewOutcome.waitingApproval => LdsNoticeTone.warning,
                    _ => LdsNoticeTone.info,
                  },
                  title: outcome.message,
                  message: state.detail,
                ),
        ),
        const SizedBox(height: 20),
        LdsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "진행 단계",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: LdsColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: LdsColors.lineSoft),
              const SizedBox(height: 20),
              LdsStepBar(
                current: current,
                verticalBelow: 520,
                steps: [
                  for (final (index, stage) in ReviewStage.values.indexed)
                    LdsStep(
                      stage.label,
                      icon: WorkflowStepIcon(index),
                      caption: switch (stages[index]) {
                        StageState.done => "완료",
                        StageState.running => "진행 중",
                        StageState.stopped => "멈춤",
                        StageState.waiting when index == current => "대기 중",
                        StageState.waiting => null,
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        if (failure != null || state.autoRefreshStopped) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: LdsNotice(
              tone: LdsNoticeTone.warning,
              icon: Icons.sync_problem,
              title: state.autoRefreshStopped
                  ? failure == null
                        ? "오래 걸려서 자동 확인을 멈췄습니다. 검토는 서버에서 계속됩니다."
                        : "진행 상황을 확인하지 못해 자동 확인을 멈췄습니다."
                  : "진행 상황을 확인하지 못했습니다. 잠시 뒤 다시 확인합니다.",
              message: failure?.message,
              action: state.autoRefreshStopped
                  ? LdsButton(
                      label: "다시 확인",
                      size: LdsButtonSize.small,
                      variant: LdsButtonVariant.outlinedNeutral,
                      onPressed: onRetry,
                    )
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// 처음 불러오기에 실패했을 때.
class ReviewProgressError extends StatelessWidget {
  const ReviewProgressError({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final ReviewProgressFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final current = failure;
    return Semantics(
      liveRegion: true,
      child: LdsNotice(
        tone: LdsNoticeTone.error,
        icon: Icons.error_outline,
        title: current != null && current.serverNotReady
            ? "서버에서 진행 상황을 아직 받을 수 없습니다."
            : "진행 상황을 불러오지 못했습니다.",
        message: current?.message ?? "잠시 뒤 다시 시도해 주세요.",
        action: LdsButton(
          label: "다시 시도",
          size: LdsButtonSize.small,
          variant: LdsButtonVariant.outlinedNeutral,
          onPressed: onRetry,
        ),
      ),
    );
  }
}

/// 지금 단계 요약(연회색 상자): 진행 고리 n/4 · '지금 단계' · 단계 이름 ·
/// 다음 단계.
class _Summary extends StatelessWidget {
  const _Summary({required this.stages, required this.current});

  final List<StageState> stages;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final total = ReviewStage.values.length;
    final now = current;
    final allDone = now == total;
    final stage = now == null
        ? null
        : ReviewStage.values[now.clamp(0, total - 1)];
    final reached = now == null ? 0 : (now + 1).clamp(0, total);
    final caption = switch (now) {
      null => "아직 시작한 단계가 없습니다.",
      _ when allDone => "모든 단계를 마쳤습니다.",
      final int index when stages[index] == StageState.stopped =>
        "이 단계에서 멈췄습니다.",
      final int index when stages[index] == StageState.waiting => "대기 중",
      final int index when index + 1 < total =>
        "다음 · ${ReviewStage.values[index + 1].label}",
      _ => "마지막 단계",
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LdsColors.canvas,
        borderRadius: BorderRadius.circular(LdsRadius.panel),
      ),
      child: Row(
        children: [
          Semantics(
            label: "$total단계 중 $reached단계",
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: reached / total,
                    strokeWidth: 5,
                    color: LdsColors.primary,
                    backgroundColor: LdsColors.line,
                  ),
                  Center(
                    child: Text(
                      "$reached/$total",
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: LdsColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "지금 단계",
                  style: TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
                ),
                const SizedBox(height: 2),
                Text(
                  stage?.label ?? "시작 전",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: LdsColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdsColors.mutedStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
