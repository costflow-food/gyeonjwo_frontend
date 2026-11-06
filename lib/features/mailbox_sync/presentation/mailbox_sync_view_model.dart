import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../auth/presentation/auth_session_view_model.dart";
import "../data/mailbox_sync_data_source.dart";
import "../domain/mailbox_sync_status.dart";

part "mailbox_sync_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// 작업 화면 상단 수신 상태. [pollInterval]마다 다시 읽어, 수신이 되살아나면
/// 안내가 저절로 사라집니다. 확인하지 못하면 null로 두고 안내하지 않습니다.
@Riverpod(retry: _noRetry)
class MailboxSyncViewModel extends _$MailboxSyncViewModel {
  static const pollInterval = Duration(seconds: 60);

  Timer? _poll;

  @override
  Future<MailboxSyncStatus?> build() async {
    ref.onDispose(() => _poll?.cancel());
    final signedIn =
        ref.watch(authSessionViewModelProvider).asData?.value.isSignedIn ??
        false;
    if (!signedIn) return null;
    final status = await _read();
    _schedule();
    return status;
  }

  Future<MailboxSyncStatus?> _read() async {
    try {
      final body = await ref
          .read(mailboxSyncDataSourceProvider)
          .fetchSyncStatus();
      return MailboxSyncStatus.fromJson(body["data"] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _schedule() {
    _poll?.cancel();
    _poll = Timer(pollInterval, _checkNow);
  }

  Future<void> _checkNow() async {
    if (!ref.mounted) return;
    final status = await _read();
    if (!ref.mounted) return;
    // Rebuild even when unchanged so a growing delay is shown.
    state = AsyncData(status);
    _schedule();
  }
}
