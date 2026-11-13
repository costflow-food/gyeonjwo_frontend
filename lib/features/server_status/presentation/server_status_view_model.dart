import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/app_visibility.dart";
import "../data/server_status_repository_impl.dart";
import "../domain/server_status.dart";

part "server_status_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(retry: _noRetry)
class ServerStatusViewModel extends _$ServerStatusViewModel {
  /// `/ready` runs a database check on the server and only feeds an
  /// informational tile, so it is read on entry and then rarely.
  static const pollInterval = Duration(minutes: 3);

  Timer? _poll;

  /// A check came due while the tab was hidden; it runs when the tab shows.
  bool _checkWaiting = false;

  @override
  Future<ServerStatus> build() async {
    ref.onDispose(() => _poll?.cancel());
    _checkWaiting = false;
    ref.listen(appVisibleProvider, (_, visible) {
      if (visible && _checkWaiting) {
        _checkWaiting = false;
        _checkNow();
      }
    });
    final status = await ref.watch(serverStatusRepositoryProvider).getStatus();
    _schedule();
    return status;
  }

  void _schedule() {
    _poll?.cancel();
    _poll = Timer(pollInterval, _checkNow);
  }

  Future<void> _checkNow() async {
    if (!ref.mounted) return;
    if (!ref.read(appVisibleProvider)) {
      _checkWaiting = true;
      return;
    }
    final status = await ref.read(serverStatusRepositoryProvider).getStatus();
    if (!ref.mounted) return;
    if (state.asData?.value != status) state = AsyncData(status);
    _schedule();
  }
}
