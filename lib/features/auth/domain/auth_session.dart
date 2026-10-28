/// Sign-in state of the current browser session.
///
/// [unconfigured] keeps the UI preview usable when Supabase settings are not
/// provided, for example in widget tests or design reviews.
enum AuthSessionStatus { unconfigured, signedOut, signedIn }

class AuthSession {
  const AuthSession({required this.status, this.email});

  const AuthSession.unconfigured() : this(status: AuthSessionStatus.unconfigured);
  const AuthSession.signedOut() : this(status: AuthSessionStatus.signedOut);

  final AuthSessionStatus status;
  final String? email;

  bool get isConfigured => status != AuthSessionStatus.unconfigured;
  bool get isSignedIn => status == AuthSessionStatus.signedIn;

  // Token refresh events keep the same session; avoid needless rebuilds.
  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.status == status && other.email == email;

  @override
  int get hashCode => Object.hash(status, email);
}
