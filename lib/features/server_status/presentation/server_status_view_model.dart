import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/server_status_repository_impl.dart";
import "../domain/server_status.dart";

part "server_status_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// 작업 화면 상단 배너용 서버 준비 상태.
///
/// [pollInterval]마다 다시 읽어, 서버가 복구되면 배너가 저절로 사라집니다.
/// 작업 화면이 모두 닫히면(자동 해제) 묻지 않습니다.
@Riverpod(retry: _noRetry)
class ServerStatusViewModel extends _$ServerStatusViewModel {
  static const pollInterval = Duration(seconds: 30);

  Timer? _poll;

  @override
  Future<ServerStatus> build() async {
    ref.onDispose(() => _poll?.cancel());
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
    final status = await ref.read(serverStatusRepositoryProvider).getStatus();
    if (!ref.mounted) return;
    if (state.asData?.value != status) state = AsyncData(status);
    _schedule();
  }
}
