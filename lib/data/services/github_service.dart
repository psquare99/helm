import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/github_telemetry.dart';
import '../../domain/models/github_user.dart';
import '../../domain/models/github_device_code.dart';
import '../../core/constants/github_config.dart';

/// GitHub Service abstraction isolating the app from API implementation details.
abstract class GitHubService {
  Future<GitHubTelemetry?> fetchTelemetry(
    String owner,
    String repo, {
    String? token,
  });

  Future<GitHubUser?> getAuthenticatedUser(String token);

  Future<List<GitHubRepositoryInfo>> getUserRepositories(String token);

  Future<Map<String, dynamic>?> getRateLimit(String? token);

  Future<GitHubDeviceCode?> requestDeviceCode({String? clientId});

  Future<GitHubTokenResponse> pollDeviceToken({
    required String deviceCode,
    String? clientId,
  });
}

/// Production implementation using GitHub REST API v3
class HttpGitHubService implements GitHubService {
  final http.Client _client;

  HttpGitHubService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<GitHubTelemetry?> fetchTelemetry(
    String owner,
    String repo, {
    String? token,
  }) async {
    final cleanOwner = owner.trim();
    final cleanRepo = repo.trim();
    if (cleanOwner.isEmpty || cleanRepo.isEmpty) return null;

    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'P2-ProjectManager',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    try {
      // 1. Fetch Repository Details
      final repoUri = Uri.parse('https://api.github.com/repos/$cleanOwner/$cleanRepo');
      final repoResponse = await _client.get(repoUri, headers: headers);

      if (repoResponse.statusCode == 404) {
        return GitHubTelemetry(
          owner: cleanOwner,
          repo: cleanRepo,
          lastFetchedAt: DateTime.now(),
          lastFetchError: 'Repository not found on GitHub',
        );
      }

      if (repoResponse.statusCode == 403) {
        final errorMsg = repoResponse.body.contains('API rate limit')
            ? 'GitHub API rate limit exceeded. Set a GitHub token in settings.'
            : 'Access denied to repository';
        return GitHubTelemetry(
          owner: cleanOwner,
          repo: cleanRepo,
          lastFetchedAt: DateTime.now(),
          lastFetchError: errorMsg,
        );
      }

      if (repoResponse.statusCode != 200) {
        return GitHubTelemetry(
          owner: cleanOwner,
          repo: cleanRepo,
          lastFetchedAt: DateTime.now(),
          lastFetchError: 'HTTP ${repoResponse.statusCode}: ${repoResponse.reasonPhrase}',
        );
      }

      final repoData = jsonDecode(repoResponse.body) as Map<String, dynamic>;
      final defaultBranch = repoData['default_branch'] as String? ?? 'main';
      final openIssues = repoData['open_issues_count'] as int? ?? 0;
      final htmlUrl = repoData['html_url'] as String? ?? 'https://github.com/$cleanOwner/$cleanRepo';

      // 2. Fetch Commits
      final commitsUri = Uri.parse(
          'https://api.github.com/repos/$cleanOwner/$cleanRepo/commits?per_page=15&sha=$defaultBranch');
      final commitsResponse = await _client.get(commitsUri, headers: headers);

      List<CommitSummary> commitsList = [];
      String? latestSha;
      String? latestMessage;
      String? latestAuthor;
      DateTime? latestDate;
      int commitsThisWeek = 0;
      int commitsThisMonth = 0;

      if (commitsResponse.statusCode == 200) {
        final commitsData = jsonDecode(commitsResponse.body) as List<dynamic>;
        final now = DateTime.now();

        for (final item in commitsData) {
          final map = item as Map<String, dynamic>;
          final sha = map['sha'] as String? ?? '';
          final commitObj = map['commit'] as Map<String, dynamic>? ?? {};
          final message = commitObj['message'] as String? ?? '';
          final authorObj = commitObj['author'] as Map<String, dynamic>? ?? {};
          final authorName = authorObj['name'] as String? ?? 'Unknown';
          final dateStr = authorObj['date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          final commitUrl = map['html_url'] as String?;

          final summary = CommitSummary(
            sha: sha,
            message: message.split('\n').first.trim(),
            author: authorName,
            date: date ?? now,
            url: commitUrl,
          );
          commitsList.add(summary);

          if (date != null) {
            final diff = now.difference(date);
            if (diff.inDays <= 7) commitsThisWeek++;
            if (diff.inDays <= 30) commitsThisMonth++;
          }
        }

        if (commitsList.isNotEmpty) {
          final top = commitsList.first;
          latestSha = top.sha;
          latestMessage = top.message;
          latestAuthor = top.author;
          latestDate = top.date;
        }
      }

      return GitHubTelemetry(
        owner: cleanOwner,
        repo: cleanRepo,
        repoUrl: htmlUrl,
        defaultBranch: defaultBranch,
        latestCommitSha: latestSha,
        latestCommitMessage: latestMessage,
        latestCommitAuthor: latestAuthor,
        latestCommitDate: latestDate,
        openIssuesCount: openIssues,
        recentCommitsThisWeek: commitsThisWeek,
        recentCommitsThisMonth: commitsThisMonth,
        recentCommits: commitsList,
        lastFetchedAt: DateTime.now(),
      );
    } catch (e) {
      return GitHubTelemetry(
        owner: cleanOwner,
        repo: cleanRepo,
        lastFetchedAt: DateTime.now(),
        lastFetchError: 'Network or parse error: $e',
      );
    }
  }

  @override
  Future<GitHubUser?> getAuthenticatedUser(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return null;

    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'P2-ProjectManager',
      'Authorization': 'Bearer $cleanToken',
    };

    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GitHubUser.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<GitHubRepositoryInfo>> getUserRepositories(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return [];

    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'P2-ProjectManager',
      'Authorization': 'Bearer $cleanToken',
    };

    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/user/repos?per_page=100&sort=updated&affiliation=owner,collaborator'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((item) => GitHubRepositoryInfo.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>?> getRateLimit(String? token) async {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'P2-ProjectManager',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/rate_limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rate = data['rate'] as Map<String, dynamic>? ?? {};
        return {
          'limit': rate['limit'] ?? 60,
          'remaining': rate['remaining'] ?? 0,
          'reset': rate['reset'] != null
              ? DateTime.fromMillisecondsSinceEpoch((rate['reset'] as int) * 1000)
              : null,
        };
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<GitHubDeviceCode?> requestDeviceCode({String? clientId}) async {
    final cid = clientId ?? GitHubConfig.clientId;
    try {
      final response = await _client.post(
        Uri.parse(GitHubConfig.deviceCodeEndpoint),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Helm-App',
        },
        body: {
          'client_id': cid,
          'scope': GitHubConfig.scopes,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GitHubDeviceCode.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<GitHubTokenResponse> pollDeviceToken({
    required String deviceCode,
    String? clientId,
  }) async {
    final cid = clientId ?? GitHubConfig.clientId;
    try {
      final response = await _client.post(
        Uri.parse(GitHubConfig.tokenEndpoint),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Helm-App',
        },
        body: {
          'client_id': cid,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('access_token')) {
          return GitHubTokenResponse(
            status: GitHubTokenStatus.success,
            accessToken: data['access_token'] as String?,
            tokenType: data['token_type'] as String?,
            scope: data['scope'] as String?,
          );
        }

        final error = data['error'] as String? ?? '';
        switch (error) {
          case 'authorization_pending':
            return const GitHubTokenResponse(status: GitHubTokenStatus.pending);
          case 'slow_down':
            return GitHubTokenResponse(
              status: GitHubTokenStatus.slowDown,
              interval: data['interval'] as int? ?? 10,
            );
          case 'expired_token':
            return const GitHubTokenResponse(
              status: GitHubTokenStatus.expired,
              errorMessage: 'The device code has expired. Please try again.',
            );
          case 'access_denied':
            return const GitHubTokenResponse(
              status: GitHubTokenStatus.accessDenied,
              errorMessage: 'Login was cancelled on GitHub.',
            );
          default:
            return GitHubTokenResponse(
              status: GitHubTokenStatus.error,
              errorMessage: data['error_description'] as String? ?? 'Authentication error',
            );
        }
      }
    } catch (e) {
      return GitHubTokenResponse(
        status: GitHubTokenStatus.error,
        errorMessage: 'Network error: $e',
      );
    }
    return const GitHubTokenResponse(
      status: GitHubTokenStatus.error,
      errorMessage: 'Failed to connect to GitHub token endpoint.',
    );
  }
}
