import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/auth_repository_impl.dart";
import "../domain/auth_failure.dart";
import "../domain/auth_session.dart";
import "../domain/gmail_connection.dart";
import "auth_session_view_model.dart";

part "gmail_connection_view_model.g.dart";

// Never retry automatically: a retry may resend Google tokens.
Duration? _noRetry(int retryCount, Object error) => null;

/// Server-confirmed Gmail connection for the signed-in user.
///
/// Right after the OAuth redirect it sends the Google tokens once and waits
/// for the server result. Otherwise it reads the connection the server keeps.
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
    return grant == null
        ? repository.fetchGmailConnection()
        : repository.connectGmail(grant);
  }

  /// Re-sends a pending grant (same idempotency key if the outcome was
  /// unknown) or reloads the server state.
  void retry() => ref.invalidateSelf();
}

/// Mail features the UI may enable. Disabling here is a convenience only;
/// the server rejects requests without the matching Google permission.
@Riverpod(keepAlive: true)
GmailCapabilities gmailCapabilities(Ref ref) {
  final session = ref.watch(authSessionViewModelProvider).asData?.value;
  if (session == null || !session.isConfigured) {
    return GmailCapabilities.preview;
  }
  final value = ref.watch(gmailConnectionViewModelProvider);
  final connection = value.asData?.value;
  if (value.isLoading || connection == null) return GmailCapabilities.unknown;
  if (!connection.hasConnection) return GmailCapabilities.none;
  return GmailCapabilities(
    canRead: connection.canRead,
    canSend: connection.canSend,
  );
}

/// Screen phase for a connection request, decided outside the View.
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
