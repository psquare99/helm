import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/github_telemetry.dart';

/// GitHub Service abstraction isolating the app from API implementation details.
abstract class GitHubService {
  Future<GitHubTelemetry?> fetchTelemetry(
    String owner,
    String repo, {
    String? token,
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
}
