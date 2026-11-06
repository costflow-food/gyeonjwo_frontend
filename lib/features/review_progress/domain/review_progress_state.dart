import "../../work_queue/domain/work_case.dart";
import "review_phase.dart";
import "review_progress_repository.dart";

/// 검토 진행 팝업이 보여 줄 마지막 진행 상태와 자동 확인 상태.
class ReviewProgress {
  const ReviewProgress({
    required this.progress,
    this.lastRunning,
    this.refreshFailure,
    this.autoRefreshStopped = false,
  });

  final CaseProgress progress;

  /// 이 팝업에서 마지막으로 본 처리 중 단계.
  final ReviewStage? lastRunning;

  /// 최근 다시 확인에 실패함. 화면은 마지막으로 받은 단계를 그대로 둡니다.
  final ReviewProgressFailure? refreshFailure;

  /// 너무 오래 걸리거나 계속 실패해 자동 확인을 멈춤. '다시 확인'으로 이어갑니다.
  final bool autoRefreshStopped;

  /// 처리 중이면 null.
  ReviewOutcome? get outcome => outcomeOf(progress.processingStep);

  List<StageState> get stages => stageStates(
    progress.processingStep,
    inputRevision: progress.inputRevision,
    stopCode: progress.stopCode,
    lastRunning: lastRunning,
  );

  /// 멈춘 이유. 서버 hold 문구가 우선이고, 없으면 오류 코드의 임시 문구입니다.
  String? get detail => stopReasonMessage(progress.hold, progress.errorCode);

  ReviewProgress withRefreshFailure(
    ReviewProgressFailure failure, {
    required bool stopped,
  }) => ReviewProgress(
    progress: progress,
    lastRunning: lastRunning,
    refreshFailure: failure,
    autoRefreshStopped: stopped,
  );
}
