import "auth_failure.dart";
import "auth_session.dart";
import "gmail_connection.dart";
import "google_provider_grant.dart";

abstract interface class AuthRepository {
  AuthSession currentSession();

  Stream<AuthSession> watchSession();

  /// Opens Google sign-in with Gmail read/send scopes and offline access.
  /// On web the page navigates away; the result arrives with the redirect.
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// OAuth error carried back on the redirect URL. Returned once per page load.
  AuthFailure? takeRedirectFailure();

  /// Tokens from this page's OAuth redirect that the server has not accepted.
  GoogleProviderGrant? pendingGoogleGrant();

  /// Sends the grant over HTTPS and waits for the server's connection result.
  Future<GmailConnection> connectGmail(GoogleProviderGrant grant);

  /// Current connection kept by the server, e.g. after a page reload.
  Future<GmailConnection> fetchGmailConnection();
}
