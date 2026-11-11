import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../work_queue/domain/work_case.dart";
import "../../work_queue/presentation/work_queue_view_model.dart";
import "../data/review_progress_repository_impl.dart";
import "../domain/review_phase.dart";
import "../domain/review_progress_repository.dart";
import "../domain/review_progress_state.dart";

part "review_progress_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// API-03 progress of one case after START or RESUME was accepted.
///
/// While the server is working it re-reads every [pollInterval], and at
/// once when Supabase Realtime says a case changed. It stops asking when
/// the case waits for the buyer or a reply, when the app is hidden
/// ([pause]), and when the dialog closes (auto-dispose). The server keeps
/// working either way.
@Riverpod(retry: _noRetry)
class ReviewProgressViewModel extends _$ReviewProgressViewModel {
  /// 08 suggests about 3 seconds for progress polling.
  static const pollInterval = Duration(seconds: 3);

  /// Stop asking after about ten minutes; '다시 확인' continues.
  static const maxPolls = 200;

  /// Consecutive failed re-reads before automatic checks stop.
  static const maxFailures = 5;

  Timer? _poll;
  Timer? _signal;
  int _polls = 0;
  int _failures = 0;
  bool _paused = false;
  bool _fetching = false;
  ReviewStage? _lastRunning;
  String? _lastStep;

  @override
  Future<ReviewProgress> build(String caseId) async {
    ref.onDispose(() {
      _poll?.cancel();
      _signal?.cancel();
    });
    // A Realtime change may be this case moving on: check now, not in 3 s.
    ref.listen(workCaseChangesProvider, (_, next) {
      if (next.hasValue) _checkSoon();
    });
    final progress = await ref
        .watch(reviewProgressRepositoryProvider)
        .getProgress(caseId);
    return _accept(progress);
  }

  void refresh() {
    _polls = 0;
    _failures = 0;
    if (state.hasValue) {
      _checkNow();
    } else {
      ref.invalidateSelf();
    }
  }

  void pause() {
    _paused = true;
    _poll?.cancel();
    _signal?.cancel();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    if (state.hasValue) _checkNow();
  }

  ReviewProgress _accept(CaseProgress progress) {
    final step = progress.processingStep;
    final changed = step != _lastStep;
    _lastStep = step;
    _lastRunning =
        runningStage(step, inputRevision: progress.inputRevision) ??
        _lastRunning;
    _poll?.cancel();
    var stopped = false;
    if (outcomeOf(step) != null) {
      if (changed) _caseChanged();
    } else if (_polls >= maxPolls) {
      stopped = true;
    } else if (!_paused) {
      _polls++;
      _poll = Timer(pollInterval, _checkNow);
    }
    return ReviewProgress(
      progress: progress,
      lastRunning: _lastRunning,
      autoRefreshStopped: stopped,
    );
  }

  /// It stopped running: show the new step and buttons in the queue and
  /// the case panel too. After the current build, where other providers
  /// must not change.
  void _caseChanged() {
    Future.microtask(() {
      if (!ref.mounted) return;
      ref.invalidate(workQueueViewModelProvider);
      ref.invalidate(caseDetailProvider(caseId));
    });
  }

  void _checkSoon() {
    if (_paused) return;
    _signal?.cancel();
    _signal = Timer(const Duration(milliseconds: 300), _checkNow);
  }

  Future<void> _checkNow() async {
    if (!ref.mounted || _fetching || _paused) return;
    _poll?.cancel();
    _fetching = true;
    try {
      final progress = await ref
          .read(reviewProgressRepositoryProvider)
          .getProgress(caseId);
      if (!ref.mounted) return;
      _failures = 0;
      state = AsyncData(_accept(progress));
    } on ReviewProgressFailure catch (failure) {
      if (!ref.mounted) return;
      _failures++;
      final last = state.asData?.value;
      if (last == null) {
        state = AsyncError(failure, StackTrace.current);
        return;
      }
      final giveUp = _failures >= maxFailures;
      state = AsyncData(last.withRefreshFailure(failure, stopped: giveUp));
      if (!giveUp && !_paused) _poll = Timer(pollInterval, _checkNow);
    } finally {
      _fetching = false;
    }
  }
}
