import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../work_queue/data/work_queue_repository_impl.dart";
import "../../work_queue/domain/work_case.dart";
import "../../work_queue/presentation/work_queue_view_model.dart";
import "../domain/review_phase.dart";

part "review_progress_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// API-03 progress of one case after START or RESUME was accepted.
///
/// Re-reads every [pollInterval] while the server is still working and
/// stops once the case waits for the buyer. Closing the dialog stops
/// polling; the server keeps working.
@Riverpod(retry: _noRetry)
class ReviewProgressViewModel extends _$ReviewProgressViewModel {
  /// 08 suggests about 3 seconds for progress polling.
  static const pollInterval = Duration(seconds: 3);

  /// Stop asking after about ten minutes; the queue still updates.
  static const maxPolls = 200;

  Timer? _poll;
  int _polls = 0;

  @override
  Future<CaseProgress> build(String caseId) async {
    ref.onDispose(() => _poll?.cancel());
    final progress = await ref
        .watch(workQueueRepositoryProvider)
        .getProgress(caseId);
    _schedule(progress);
    return progress;
  }

  void refresh() {
    _polls = 0;
    ref.invalidateSelf();
  }

  void _schedule(CaseProgress progress) {
    _poll?.cancel();
    if (outcomeOf(progress.processingStep) != null) {
      // It stopped running: show the new step in the queue too. After the
      // current build, where other providers must not change.
      Future.microtask(() {
        if (ref.mounted) ref.invalidate(workQueueViewModelProvider);
      });
      return;
    }
    if (++_polls > maxPolls) return;
    _poll = Timer(pollInterval, _pollOnce);
  }

  Future<void> _pollOnce() async {
    if (!ref.mounted) return;
    try {
      final progress = await ref
          .read(workQueueRepositoryProvider)
          .getProgress(caseId);
      if (!ref.mounted) return;
      state = AsyncData(progress);
      _schedule(progress);
    } catch (_) {
      // Keep the last step on screen and try again.
      if (ref.mounted) _poll = Timer(pollInterval, _pollOnce);
    }
  }
}
