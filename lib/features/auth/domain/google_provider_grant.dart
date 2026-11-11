class GoogleProviderGrant {
  const GoogleProviderGrant({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  @override
  String toString() => "GoogleProviderGrant(<redacted>)";
}
