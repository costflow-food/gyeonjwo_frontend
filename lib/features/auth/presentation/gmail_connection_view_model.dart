import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/auth_repository_impl.dart";
import "../domain/auth_failure.dart";
import "../domain/auth_session.dart";
import "../domain/gmail_connection.dart";
import "auth_session_view_model.dart";

part "gmail_connection_view_model.g.dart";

// Never retry automatically: a retry may resend Google tokens.
Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
class GmailConnectionViewModel extends _$GmailConnectionViewModel {
  @override
  FutureOr<GmailConnection> build() {
    // AuthSession compares by status and email, so token refreshes do not
    // rebuild this provider or resend the grant.
    final status = ref.watch(authSessionViewModelProvider).asData?.value.status;
    if (status != AuthSessionStatus.signedIn) {
      return const GmailConnection.notConnected();
    }
    final repository = ref.read(authRepositoryProvider);
    final grant = repository.pendingGoogleGrant();
    // In the app, consenting again with the same account returns to this
    // process and the session compares equal, so nothing above rebuilds.
    // Rebuild once when a provider token this build has not seen arrives.
    final subscription = repository.watchSession().listen((_) {
      final next = repository.pendingGoogleGrant();
      if (next != null && next.accessToken != grant?.accessToken) {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(subscription.cancel);
    return grant == null
        ? repository.fetchGmailConnection()
        : repository.connectGmail(grant);
  }

  void retry() => ref.invalidateSelf();
}

@Riverpod(keepAlive: true)
GmailCapabilities gmailCapabilities(Ref ref) {
  final session = ref.watch(authSessionViewModelProvider).asData?.value;
  if (session == null) return GmailCapabilities.unknown;
  final value = ref.watch(gmailConnectionViewModelProvider);
  final connection = value.asData?.value;
  if (value.isLoading || connection == null) return GmailCapabilities.unknown;
  if (!connection.hasConnection) return GmailCapabilities.none;
  return GmailCapabilities(
    canRead: connection.canRead,
    canSend: connection.canSend,
  );
}

extension GmailConnectionState on AsyncValue<GmailConnection> {
  AuthFailure? get authFailure =>
      hasError && error is AuthFailure ? error as AuthFailure : null;

  GmailConnectionPhase get connectionPhase {
    if (isLoading) return GmailConnectionPhase.connecting;
    if (hasError) {
      return authFailure?.code == AuthFailureCode.sessionExpired
          ? GmailConnectionPhase.reconnect
          : GmailConnectionPhase.failed;
    }
    return asData?.value.phase ?? GmailConnectionPhase.connecting;
  }
}
