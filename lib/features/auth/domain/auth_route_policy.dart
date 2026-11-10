import "auth_session.dart";

/// Screens reachable before sign-in. Consent guidance must stay readable.
const publicAuthPaths = {"/login", "/login/permissions"};

/// Route guard for screen flow only. The server authorizes every API request.
///
/// After sign-in the connection screen only stays up while the server is
/// connecting Gmail or when something needs the user's attention (a denied
/// permission, a failure, a reconnect). [gmailReady] means the server
/// confirmed both read and send, so the app goes straight to the work queue.
String? authRedirect(
  AuthSessionStatus? status,
  String path, {
  bool gmailReady = false,
}) => switch (status) {
  null => null,
  AuthSessionStatus.signedOut =>
    publicAuthPaths.contains(path) ? null : "/login",
  AuthSessionStatus.signedIn => switch (path) {
    "/login" => "/login/connection",
    "/login/connection" when gmailReady => "/",
    _ => null,
  },
};
