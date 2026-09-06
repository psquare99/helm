import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/project_task.dart';
import '../../domain/models/project_milestone.dart';
import '../../domain/models/project_note.dart';
import '../../domain/models/github_telemetry.dart';

/// Clean sample demo projects for exploring the Helm command center.
/// Used only when the user explicitly chooses to load sample projects.
class SeedData {
  static List<Project> getInitialProjects() {
    final now = DateTime.now();

    return [
      // 1. Apex Mobile
      Project(
        id: 'sample_apex',
        name: 'Apex Mobile',
        description: 'Cross-platform mobile application with offline-first local database architecture',
        type: ProjectType.flutterApp,
        localPath: null,
        humanStatus: ProjectHumanStatus.active,
        priority: ProjectPriority.p0,
        currentMilestone: 'v1.0 Dashboard & Authentication',
        nextAction: 'Finalize biometric authentication flow',
        github: GitHubTelemetry(
          owner: 'helm-showcase',
          repo: 'apex-mobile',
          repoUrl: 'https://github.com/helm-showcase/apex-mobile',
          defaultBranch: 'main',
          latestCommitSha: '7f9a2bc',
          latestCommitMessage: 'feat: add biometric lock mechanism',
          latestCommitAuthor: 'Helm Lead',
          latestCommitDate: now.subtract(const Duration(days: 2)),
          recentCommitsThisWeek: 6,
          recentCommitsThisMonth: 18,
          openIssuesCount: 3,
          lastFetchedAt: now,
        ),
        milestones: [
          ProjectMilestone(
            id: 'm-apex-1',
            title: 'Foundational Design System',
            status: MilestoneStatus.completed,
            completedDate: now.subtract(const Duration(days: 20)),
          ),
          ProjectMilestone(
            id: 'm-apex-2',
            title: 'v1.0 Dashboard & Authentication',
            description: 'Core navigation, session management, and dashboard layout',
            status: MilestoneStatus.inProgress,
            isCurrent: true,
          ),
          ProjectMilestone(
            id: 'm-apex-3',
            title: 'Cloud Sync Engine',
            status: MilestoneStatus.pending,
          ),
        ],
        tasks: [
          ProjectTask(
            id: 't-apex-1',
            title: 'Finalize biometric authentication flow',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          ProjectTask(
            id: 't-apex-2',
            title: 'Write offline database migration tests',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          ProjectTask(
            id: 't-apex-3',
            title: 'Implement calm typography scale',
            isCompleted: true,
            createdAt: now.subtract(const Duration(days: 15)),
            completedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
        notes: [
          ProjectNote(
            id: 'n-apex-1',
            title: 'Offline Storage Strategy',
            content: 'Persist all user workspace models locally first. Network synchronization must run opportunistically in the background.',
            category: NoteCategory.architecture,
            createdAt: now.subtract(const Duration(days: 8)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),

      // 2. Nexus API Gateway
      Project(
        id: 'sample_nexus',
        name: 'Nexus API Gateway',
        description: 'High-performance cloud microservices router and telemetry pipeline',
        type: ProjectType.service,
        localPath: null,
        humanStatus: ProjectHumanStatus.active,
        priority: ProjectPriority.p1,
        currentMilestone: 'Rate Limiting & Token Bucket',
        nextAction: 'Deploy distributed Redis rate limiter',
        github: GitHubTelemetry(
          owner: 'helm-showcase',
          repo: 'nexus-gateway',
          repoUrl: 'https://github.com/helm-showcase/nexus-gateway',
          defaultBranch: 'main',
          latestCommitSha: '4c8e11a',
          latestCommitMessage: 'perf: optimize connection pool re-use',
          latestCommitAuthor: 'Core Team',
          latestCommitDate: now.subtract(const Duration(days: 5)),
          recentCommitsThisWeek: 2,
          recentCommitsThisMonth: 11,
          openIssuesCount: 1,
          lastFetchedAt: now,
        ),
        milestones: [
          ProjectMilestone(
            id: 'm-nexus-1',
            title: 'Rate Limiting & Token Bucket',
            description: 'Protect upstream routes with sliding window rate limiting',
            status: MilestoneStatus.inProgress,
            isCurrent: true,
          ),
        ],
        tasks: [
          ProjectTask(
            id: 't-nexus-1',
            title: 'Deploy distributed Redis rate limiter',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 4)),
          ),
        ],
        notes: [
          ProjectNote(
            id: 'n-nexus-1',
            title: 'Zero Downtime Deployment Protocol',
            content: 'Gracefully drain active TCP connections before terminating worker processes.',
            category: NoteCategory.decision,
            createdAt: now.subtract(const Duration(days: 12)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),

      // 3. Compass CLI
      Project(
        id: 'sample_compass',
        name: 'Compass CLI',
        description: 'Command line workflow automation and environment scaffolding tool',
        type: ProjectType.cliPackage,
        localPath: null,
        humanStatus: ProjectHumanStatus.paused,
        priority: ProjectPriority.p2,
        currentMilestone: 'Terminal UI Refactor',
        nextAction: 'Migrate to modern terminal rendering library',
        github: null,
        milestones: [
          ProjectMilestone(
            id: 'm-compass-1',
            title: 'Terminal UI Refactor',
            status: MilestoneStatus.inProgress,
            isCurrent: true,
          ),
        ],
        tasks: [
          ProjectTask(
            id: 't-compass-1',
            title: 'Migrate to modern terminal rendering library',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 20)),
          ),
        ],
        notes: [],
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),

      // 4. Horizon Studio (Demonstrates honest empty state)
      Project(
        id: 'sample_horizon',
        name: 'Horizon Studio',
        description: 'Next-generation spatial design workspace and canvas editor',
        type: ProjectType.desktopApp,
        localPath: null,
        humanStatus: null, // Honest empty state: "Status not set"
        priority: ProjectPriority.none,
        currentMilestone: null,
        nextAction: null,
        github: null,
        milestones: [],
        tasks: [],
        notes: [],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
    ];
  }
}
