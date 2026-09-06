/// GitHub Device Code response model from POST /login/device/code
class GitHubDeviceCode {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;

  const GitHubDeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  factory GitHubDeviceCode.fromJson(Map<String, dynamic> json) {
    return GitHubDeviceCode(
      deviceCode: json['device_code'] as String? ?? '',
      userCode: json['user_code'] as String? ?? '',
      verificationUri: json['verification_uri'] as String? ?? 'https://github.com/login/device',
      expiresIn: json['expires_in'] as int? ?? 900,
      interval: json['interval'] as int? ?? 5,
    );
  }
}

/// Status of the polled token request
enum GitHubTokenStatus {
  success,
  pending,
  slowDown,
  expired,
  accessDenied,
  error,
}

/// Response returned from polling POST /login/oauth/access_token
class GitHubTokenResponse {
  final GitHubTokenStatus status;
  final String? accessToken;
  final String? tokenType;
  final String? scope;
  final String? errorMessage;
  final int? interval;

  const GitHubTokenResponse({
    required this.status,
    this.accessToken,
    this.tokenType,
    this.scope,
    this.errorMessage,
    this.interval,
  });
}
