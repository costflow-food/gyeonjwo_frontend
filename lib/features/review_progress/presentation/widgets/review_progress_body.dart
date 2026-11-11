import "package:flutter/material.dart";

import "../../../../shared/workspace_colors.dart";
import "../../domain/review_phase.dart";
import "../../domain/review_progress_repository.dart";
import "../../domain/review_progress_state.dart";

/// The pipeline steps from API-03, and why it stopped once it did.
class ReviewProgressBody extends StatelessWidget {
  const ReviewProgressBody({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final ReviewProgress state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;
    final stages = state.stages;
    final detail = state.detail;
    final failure = state.refreshFailure;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stage in ReviewStage.values)
            _StageRow(stage: stage, state: stages[stage.index]),
          if (outcome != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: _Box(
                children: [
                  Text(
                    outcome.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: outcome.stopped ? danger : context.palette.ink,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (failure != null || state.autoRefreshStopped) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: _Box(
                children: [
                  Text(
                    state.autoRefreshStopped
                        ? failure == null
                              ? "오래 걸려서 자동 확인을 멈췄습니다. 검토는 서버에서 계속됩니다."
                              : "진행 상황을 확인하지 못해 자동 확인을 멈췄습니다."
                        : "진행 상황을 확인하지 못했습니다. 잠시 뒤 다시 확인합니다.",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (failure != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      failure.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                  if (state.autoRefreshStopped) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: onRetry,
                        child: const Text("다시 확인"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The first check failed, so there is no step to show yet.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Semantics(
        liveRegion: true,
        child: _Box(
          children: [
            Text(
              current != null && current.serverNotReady
                  ? "서버에서 진행 상황을 아직 받을 수 없습니다."
                  : "진행 상황을 불러오지 못했습니다.",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: danger,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              current?.message ?? "잠시 뒤 다시 시도해 주세요.",
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text("다시 시도"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.palette.panel,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.state});

  final ReviewStage stage;
  final StageState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 20,
          child: switch (state) {
            StageState.done => const Icon(
              Icons.check_circle,
              size: 20,
              color: Color(0xFF00754A),
            ),
            StageState.running => Padding(
              padding: EdgeInsets.all(2),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.palette.accent,
              ),
            ),
            StageState.stopped => const Icon(
              Icons.pause_circle_outline,
              size: 20,
              color: danger,
            ),
            StageState.waiting => Icon(
              Icons.radio_button_unchecked,
              size: 20,
              color: context.palette.line,
            ),
          },
        ),
        const SizedBox(width: 12),
        Text(
          stage.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: state == StageState.running
                ? FontWeight.w700
                : FontWeight.w400,
            color: state == StageState.waiting
                ? context.palette.muted
                : context.palette.ink,
          ),
        ),
        if (state == StageState.running) ...[
          const SizedBox(width: 8),
          Text(
            "진행 중",
            style: TextStyle(fontSize: 14, color: context.palette.muted),
          ),
        ],
      ],
    ),
  );
}
