import 'package:flutter_test/flutter_test.dart';
import 'package:helm/domain/models/project.dart';
import 'package:helm/domain/models/project_status.dart';
import 'package:helm/domain/models/project_pulse.dart';
import 'package:helm/domain/models/github_telemetry.dart';
import 'package:helm/domain/models/github_user.dart';
import 'package:helm/core/constants/seed_data.dart';

void main() {
  group('Project State & Philosophy Tests', () {
    test('Human status is authoritative and distinct from observed activity', () {
      final now = DateTime.now();
      // WAYFINDER is declared Paused by the human, with no GitHub connection
      final wayfinder = Project(
        id: 'wayfinder',
        name: 'WAYFINDER',
        humanStatus: ProjectHumanStatus.paused,
        github: null,
        createdAt: now,
        updatedAt: now,
      );

      final pulse = ProjectPulseData.fromProject(wayfinder);
      expect(pulse.humanStatusText, 'Paused');
      expect(pulse.observedActivity, ObservedActivity.notConnected);
      expect(pulse.observedActivityText, 'GitHub Not Connected');
      expect(pulse.nextActionText, 'No next action defined');
      expect(pulse.milestoneText, 'No milestones yet');
    });

    test('Active project with recent commits correctly calculates observed activity', () {
      final now = DateTime.now();
      final prime = Project(
        id: 'prime',
        name: 'Prime',
        humanStatus: ProjectHumanStatus.active,
        currentMilestone: 'Dashboard',
        nextAction: 'Finish liability calculations',
        github: GitHubTelemetry(
          owner: 'psquare99',
          repo: 'prime',
          latestCommitDate: now,
          recentCommitsThisWeek: 8,
          openIssuesCount: 2,
          lastFetchedAt: now,
        ),
        createdAt: now,
        updatedAt: now,
      );

      final pulse = ProjectPulseData.fromProject(prime);
      expect(pulse.humanStatus, ProjectHumanStatus.active);
      expect(pulse.humanStatusText, 'Active');
      expect(pulse.observedActivity, ObservedActivity.veryActive);
      expect(pulse.lastActivityText, 'Today');
      expect(pulse.recentActivityText, '8 commits this week');
      expect(pulse.openIssuesCount, 2);
      expect(pulse.milestoneText, 'Dashboard');
      expect(pulse.nextActionText, 'Finish liability calculations');
    });

    test('Sample portfolio contains clean illustrative projects with honest empty states', () {
      final initialProjects = SeedData.getInitialProjects();
      expect(initialProjects.isNotEmpty, isTrue);

      final names = initialProjects.map((p) => p.name).toList();
      expect(names.contains('Apex Mobile'), isTrue);
      expect(names.contains('Nexus API Gateway'), isTrue);
      expect(names.contains('Compass CLI'), isTrue);
      expect(names.contains('Horizon Studio'), isTrue);

      // Verify honest empty states on unconnected projects
      final horizon = initialProjects.firstWhere((p) => p.name == 'Horizon Studio');
      expect(horizon.humanStatus, isNull);
      expect(horizon.statusDisplay, 'Status not set');
      expect(horizon.github, isNull);
      expect(horizon.nextActionDisplay, 'No next action defined');
      expect(horizon.milestoneDisplay, 'No milestones yet');
    });

    test('GitHubUser and GitHubRepositoryInfo parse JSON accurately', () {
      final userJson = {
        'login': 'psquare99',
        'id': 12345,
        'avatar_url': 'https://avatars.githubusercontent.com/u/12345',
        'html_url': 'https://github.com/psquare99',
        'name': 'P²',
        'bio': 'Systems Architect',
        'public_repos': 12,
        'total_private_repos': 5,
      };

      final user = GitHubUser.fromJson(userJson);
      expect(user.login, 'psquare99');
      expect(user.displayName, 'P²');
      expect(user.publicRepos, 12);
      expect(user.totalPrivateRepos, 5);

      final repoJson = {
        'name': 'project-manager',
        'full_name': 'psquare99/project-manager',
        'owner': {'login': 'psquare99'},
        'description': 'Personal command center for projects',
        'html_url': 'https://github.com/psquare99/project-manager',
        'private': false,
        'fork': false,
        'language': 'Dart',
        'stargazers_count': 14,
        'open_issues_count': 0,
        'default_branch': 'main',
      };

      final repo = GitHubRepositoryInfo.fromJson(repoJson);
      expect(repo.name, 'project-manager');
      expect(repo.fullName, 'psquare99/project-manager');
      expect(repo.owner, 'psquare99');
      expect(repo.language, 'Dart');
      expect(repo.stargazersCount, 14);
      expect(repo.isPrivate, isFalse);
    });
  });
}
