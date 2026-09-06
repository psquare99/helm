/// Configuration for GitHub OAuth integration in Helm.
class GitHubConfig {
  /// Public Client ID registered in GitHub Developer Settings.
  /// Safe to be included in client binaries as it does not contain secrets.
  static const String clientId = 'Ov23liKbqqJxwVUJRSmr';

  /// Requested OAuth permission scopes.
  static const String scopes = 'repo,read:user';

  /// GitHub OAuth endpoints
  static const String deviceCodeEndpoint = 'https://github.com/login/device/code';
  static const String tokenEndpoint = 'https://github.com/login/oauth/access_token';
  static const String verificationUrl = 'https://github.com/login/device';
}
