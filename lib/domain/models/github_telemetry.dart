import 'project_status.dart';

/// Lightweight summary of a git commit
class CommitSummary {
  final String sha;
  final String message;
  final String author;
  final DateTime date;
  final String? url;

  const CommitSummary({
    required this.sha,
    required this.message,
    required this.author,
    required this.date,
    this.url,
  });

  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  Map<String, dynamic> toJson() => {
        'sha': sha,
        'message': message,
        'author': author,
        'date': date.toIso8601String(),
        'url': url,
      };

  factory CommitSummary.fromJson(Map<String, dynamic> json) => CommitSummary(
        sha: json['sha'] as String? ?? '',
        message: json['message'] as String? ?? '',
        author: json['author'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        url: json['url'] as String?,
      );
}

/// External GitHub telemetry observed for a project.
/// This data is external signal and NEVER alters human status.
class GitHubTelemetry {
  final String owner;
  final String repo;
  final String? repoUrl;
  final String defaultBranch;
  final String? latestCommitSha;
  final String? latestCommitMessage;
  final String? latestCommitAuthor;
  final DateTime? latestCommitDate;
  final int openIssuesCount;
  final int recentCommitsThisWeek;
  final int recentCommitsThisMonth;
  final List<CommitSummary> recentCommits;
  final DateTime lastFetchedAt;
  final String? lastFetchError;

  const GitHubTelemetry({
    required this.owner,
    required this.repo,
    this.repoUrl,
    this.defaultBranch = 'main',
    this.latestCommitSha,
    this.latestCommitMessage,
    this.latestCommitAuthor,
    this.latestCommitDate,
    this.openIssuesCount = 0,
    this.recentCommitsThisWeek = 0,
    this.recentCommitsThisMonth = 0,
    this.recentCommits = const [],
    required this.lastFetchedAt,
    this.lastFetchError,
  });

  String get fullName => '$owner/$repo';
  String get shortLatestSha => latestCommitSha != null && latestCommitSha!.length > 7
      ? latestCommitSha!.substring(0, 7)
      : (latestCommitSha ?? '');

  /// Computes the observed activity strictly from commit timestamps
  ObservedActivity get observedActivity {
    if (latestCommitDate == null) {
      return recentCommits.isEmpty ? ObservedActivity.noActivity : ObservedActivity.stale;
    }
    final now = DateTime.now();
    final difference = now.difference(latestCommitDate!);
    if (difference.inHours <= 72) {
      return ObservedActivity.veryActive;
    } else if (difference.inDays <= 7) {
      return ObservedActivity.active;
    } else if (difference.inDays <= 30) {
      return ObservedActivity.quiet;
    } else {
      return ObservedActivity.stale;
    }
  }

  GitHubTelemetry copyWith({
    String? owner,
    String? repo,
    String? repoUrl,
    String? defaultBranch,
    String? latestCommitSha,
    String? latestCommitMessage,
    String? latestCommitAuthor,
    DateTime? latestCommitDate,
    int? openIssuesCount,
    int? recentCommitsThisWeek,
    int? recentCommitsThisMonth,
    List<CommitSummary>? recentCommits,
    DateTime? lastFetchedAt,
    String? lastFetchError,
  }) {
    return GitHubTelemetry(
      owner: owner ?? this.owner,
      repo: repo ?? this.repo,
      repoUrl: repoUrl ?? this.repoUrl,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      latestCommitSha: latestCommitSha ?? this.latestCommitSha,
      latestCommitMessage: latestCommitMessage ?? this.latestCommitMessage,
      latestCommitAuthor: latestCommitAuthor ?? this.latestCommitAuthor,
      latestCommitDate: latestCommitDate ?? this.latestCommitDate,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      recentCommitsThisWeek: recentCommitsThisWeek ?? this.recentCommitsThisWeek,
      recentCommitsThisMonth: recentCommitsThisMonth ?? this.recentCommitsThisMonth,
      recentCommits: recentCommits ?? this.recentCommits,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastFetchError: lastFetchError,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'repoUrl': repoUrl,
        'defaultBranch': defaultBranch,
        'latestCommitSha': latestCommitSha,
        'latestCommitMessage': latestCommitMessage,
        'latestCommitAuthor': latestCommitAuthor,
        'latestCommitDate': latestCommitDate?.toIso8601String(),
        'openIssuesCount': openIssuesCount,
        'recentCommitsThisWeek': recentCommitsThisWeek,
        'recentCommitsThisMonth': recentCommitsThisMonth,
        'recentCommits': recentCommits.map((c) => c.toJson()).toList(),
        'lastFetchedAt': lastFetchedAt.toIso8601String(),
        'lastFetchError': lastFetchError,
      };

  factory GitHubTelemetry.fromJson(Map<String, dynamic> json) => GitHubTelemetry(
        owner: json['owner'] as String? ?? '',
        repo: json['repo'] as String? ?? '',
        repoUrl: json['repoUrl'] as String?,
        defaultBranch: json['defaultBranch'] as String? ?? 'main',
        latestCommitSha: json['latestCommitSha'] as String?,
        latestCommitMessage: json['latestCommitMessage'] as String?,
        latestCommitAuthor: json['latestCommitAuthor'] as String?,
        latestCommitDate: json['latestCommitDate'] != null
            ? DateTime.tryParse(json['latestCommitDate'] as String)
            : null,
        openIssuesCount: json['openIssuesCount'] as int? ?? 0,
        recentCommitsThisWeek: json['recentCommitsThisWeek'] as int? ?? 0,
        recentCommitsThisMonth: json['recentCommitsThisMonth'] as int? ?? 0,
        recentCommits: (json['recentCommits'] as List<dynamic>?)
                ?.map((c) => CommitSummary.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        lastFetchedAt: DateTime.tryParse(json['lastFetchedAt'] as String? ?? '') ??
            DateTime.now(),
        lastFetchError: json['lastFetchError'] as String?,
      );
}
