import "auth_session.dart";

/// Screens reachable before sign-in. Consent guidance must stay readable.
const publicAuthPaths = {"/login", "/login/permissions"};

/// Route guard for screen flow only. The server authorizes every API request.
String? authRedirect(AuthSessionStatus? status, String path) => switch (status) {
  null || AuthSessionStatus.unconfigured => null,
  AuthSessionStatus.signedOut =>
    publicAuthPaths.contains(path) ? null : "/login",
  AuthSessionStatus.signedIn => path == "/login" ? "/login/connection" : null,
};
