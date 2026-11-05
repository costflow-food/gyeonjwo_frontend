import "package:flutter/material.dart";

import "../../../../shared/workspace_colors.dart";
import "../../../work_queue/domain/work_case.dart";
import "../../domain/review_phase.dart";

/// The pipeline steps from API-03, and why it stopped once it did.
class ReviewProgressBody extends StatelessWidget {
  const ReviewProgressBody({super.key, required this.progress});

  final CaseProgress progress;

  @override
  Widget build(BuildContext context) {
    final outcome = outcomeOf(progress.processingStep);
    final current = outcome == null
        ? runningStage(progress.processingStep) ?? ReviewStage.received
        : reachedStage(outcome, errorCode: progress.errorCode);
    final detail =
        progress.hold?.message ?? stopReasonMessage(progress.errorCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stage in ReviewStage.values)
            _StageRow(
              stage: stage,
              state: switch (stage.index.compareTo(current.index)) {
                < 0 => _StageState.done,
                0 when outcome == null => _StageState.running,
                0 when outcome != null && outcome.stopped =>
                  _StageState.stopped,
                0 => _StageState.done,
                _ => _StageState.waiting,
              },
            ),
          if (outcome != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outcome.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: outcome.stopped ? accent : ink,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        detail,
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _StageState { done, running, stopped, waiting }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.state});

  final ReviewStage stage;
  final _StageState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 20,
          child: switch (state) {
            _StageState.done => const Icon(
              Icons.check_circle,
              size: 20,
              color: Color(0xFF4B9138),
            ),
            _StageState.running => const Padding(
              padding: EdgeInsets.all(2),
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            ),
            _StageState.stopped => const Icon(
              Icons.pause_circle_outline,
              size: 20,
              color: accent,
            ),
            _StageState.waiting => const Icon(
              Icons.radio_button_unchecked,
              size: 20,
              color: line,
            ),
          },
        ),
        const SizedBox(width: 12),
        Text(
          stage.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: state == _StageState.running
                ? FontWeight.w700
                : FontWeight.w400,
            color: state == _StageState.waiting ? muted : ink,
          ),
        ),
        if (state == _StageState.running) ...[
          const SizedBox(width: 8),
          const Text("진행 중", style: TextStyle(fontSize: 12, color: muted)),
        ],
      ],
    ),
  );
}
