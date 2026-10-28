import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/auth_repository_impl.dart";
import "../domain/auth_failure.dart";
import "../domain/auth_session.dart";

part "auth_session_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// Sign-in state for route guards, the sidebar and the account screen.
@Riverpod(keepAlive: true, retry: _noRetry)
class AuthSessionViewModel extends _$AuthSessionViewModel {
  @override
  FutureOr<AuthSession> build() {
    final repository = ref.watch(authRepositoryProvider);
    // The auth stream replays past events to new listeners, so read the live
    // session on each event instead of trusting the event's own snapshot.
    final subscription = repository.watchSession().listen((_) {
      if (ref.mounted) state = AsyncData(repository.currentSession());
    });
    ref.onDispose(subscription.cancel);
    return repository.currentSession();
  }

  /// Leaves the app for Google's account and consent screens.
  Future<void> signInWithGoogle() =>
      ref.read(authRepositoryProvider).signInWithGoogle();

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) return;
    state = AsyncData(ref.read(authRepositoryProvider).currentSession());
  }
}

/// OAuth error returned on the redirect URL, read once per page load.
@Riverpod(keepAlive: true)
AuthFailure? authRedirectFailure(Ref ref) =>
    ref.watch(authRepositoryProvider).takeRedirectFailure();
