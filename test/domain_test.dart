import 'package:flutter_test/flutter_test.dart';
import 'package:project_manager/domain/models/project.dart';
import 'package:project_manager/domain/models/project_status.dart';
import 'package:project_manager/domain/models/project_pulse.dart';
import 'package:project_manager/domain/models/github_telemetry.dart';
import 'package:project_manager/core/constants/seed_data.dart';

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

    test('Seed portfolio contains real projects with honest empty states', () {
      final initialProjects = SeedData.getInitialProjects();
      expect(initialProjects.isNotEmpty, isTrue);

      final names = initialProjects.map((p) => p.name).toList();
      expect(names.contains('Prime'), isTrue);
      expect(names.contains('P² Studio'), isTrue);
      expect(names.contains('Curio'), isTrue);
      expect(names.contains('Nook'), isTrue);
      expect(names.contains('Wayfarer'), isTrue);
      expect(names.contains('WAYFINDER'), isTrue);
      expect(names.contains('HEARTBEAT'), isTrue);

      // Verify honest empty states on unconnected projects
      final heartbeat = initialProjects.firstWhere((p) => p.name == 'HEARTBEAT');
      expect(heartbeat.humanStatus, isNull);
      expect(heartbeat.statusDisplay, 'Status not set');
      expect(heartbeat.github, isNull);
      expect(heartbeat.nextActionDisplay, 'No next action defined');
      expect(heartbeat.milestoneDisplay, 'No milestones yet');
    });
  });
}
