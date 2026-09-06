/// Authenticated GitHub user account details
class GitHubUser {
  final String login;
  final int id;
  final String avatarUrl;
  final String htmlUrl;
  final String? name;
  final String? bio;
  final int publicRepos;
  final int? totalPrivateRepos;

  const GitHubUser({
    required this.login,
    required this.id,
    required this.avatarUrl,
    required this.htmlUrl,
    this.name,
    this.bio,
    this.publicRepos = 0,
    this.totalPrivateRepos,
  });

  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : login;

  Map<String, dynamic> toJson() => {
        'login': login,
        'id': id,
        'avatar_url': avatarUrl,
        'html_url': htmlUrl,
        'name': name,
        'bio': bio,
        'public_repos': publicRepos,
        'total_private_repos': totalPrivateRepos,
      };

  factory GitHubUser.fromJson(Map<String, dynamic> json) => GitHubUser(
        login: json['login'] as String? ?? '',
        id: json['id'] as int? ?? 0,
        avatarUrl: json['avatar_url'] as String? ?? '',
        htmlUrl: json['html_url'] as String? ?? '',
        name: json['name'] as String?,
        bio: json['bio'] as String?,
        publicRepos: json['public_repos'] as int? ?? 0,
        totalPrivateRepos: json['total_private_repos'] as int?,
      );
}

/// Discovered GitHub repository available for selective import into Project Manager
class GitHubRepositoryInfo {
  final String name;
  final String fullName;
  final String owner;
  final String? description;
  final String htmlUrl;
  final bool isPrivate;
  final bool isFork;
  final String? language;
  final int stargazersCount;
  final int openIssuesCount;
  final String defaultBranch;
  final DateTime? updatedAt;
  final DateTime? pushedAt;

  const GitHubRepositoryInfo({
    required this.name,
    required this.fullName,
    required this.owner,
    this.description,
    required this.htmlUrl,
    this.isPrivate = false,
    this.isFork = false,
    this.language,
    this.stargazersCount = 0,
    this.openIssuesCount = 0,
    this.defaultBranch = 'main',
    this.updatedAt,
    this.pushedAt,
  });

  factory GitHubRepositoryInfo.fromJson(Map<String, dynamic> json) {
    final ownerObj = json['owner'] as Map<String, dynamic>? ?? {};
    final ownerLogin = ownerObj['login'] as String? ?? '';

    return GitHubRepositoryInfo(
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      owner: ownerLogin,
      description: json['description'] as String?,
      htmlUrl: json['html_url'] as String? ?? '',
      isPrivate: json['private'] as bool? ?? false,
      isFork: json['fork'] as bool? ?? false,
      language: json['language'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      pushedAt: json['pushed_at'] != null ? DateTime.tryParse(json['pushed_at'] as String) : null,
    );
  }
}
