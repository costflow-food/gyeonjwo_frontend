import "auth_failure.dart";
import "auth_session.dart";
import "gmail_connection.dart";
import "google_provider_grant.dart";

abstract interface class AuthRepository {
  AuthSession currentSession();

  Stream<AuthSession> watchSession();

  /// Opens Google sign-in with Gmail read/send scopes and offline access.
  /// On web the page navigates away; the result arrives with the redirect.
  /// In the app it completes when the browser returns, throwing [AuthFailure]
  /// if Google or Supabase reported an error.
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// OAuth error carried back on the redirect URL. Returned once per page load.
  AuthFailure? takeRedirectFailure();

  GoogleProviderGrant? pendingGoogleGrant();

  Future<GmailConnection> connectGmail(GoogleProviderGrant grant);

  Future<GmailConnection> fetchGmailConnection();
}
