/// Google tokens returned with this page's OAuth redirect.
///
/// They stay in memory only until the server accepts them. The server checks
/// the granted scopes itself, so the client never reports permissions.
class GoogleProviderGrant {
  const GoogleProviderGrant({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  @override
  String toString() => "GoogleProviderGrant(<redacted>)";
}
