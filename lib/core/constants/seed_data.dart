import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/project_task.dart';
import '../../domain/models/project_milestone.dart';
import '../../domain/models/project_note.dart';
import '../../domain/models/github_telemetry.dart';

/// Seed projects derived strictly from the user's real projects in C:\Projects
/// and the master build brief. No fictional projects or fake dates.
class SeedData {
  static List<Project> getInitialProjects() {
    final now = DateTime.now();

    return [
      // 1. Prime
      Project(
        id: 'prime',
        name: 'Prime',
        description: 'Personal finance, asset allocation, and liability management system',
        type: ProjectType.flutterApp,
        localPath: r'C:\Projects\prime',
        humanStatus: ProjectHumanStatus.active,
        priority: ProjectPriority.p1,
        currentMilestone: 'Dashboard',
        nextAction: 'Finish liability calculations',
        github: GitHubTelemetry(
          owner: 'psquare99',
          repo: 'prime',
          repoUrl: 'https://github.com/psquare99/prime',
          defaultBranch: 'main',
          latestCommitSha: '2eff54a',
          latestCommitMessage: 'Improve README with screenshots',
          latestCommitAuthor: 'psquare99',
          latestCommitDate: now.subtract(const Duration(days: 30)),
          recentCommitsThisWeek: 0,
          recentCommitsThisMonth: 1,
          openIssuesCount: 0,
          lastFetchedAt: now,
        ),
        milestones: [
          ProjectMilestone(
            id: 'm-prime-1',
            title: 'Prime v1.0 Release',
            status: MilestoneStatus.completed,
            completedDate: now.subtract(const Duration(days: 35)),
          ),
          ProjectMilestone(
            id: 'm-prime-2',
            title: 'Dashboard',
            description: 'Core financial overview and metrics visualization',
            status: MilestoneStatus.inProgress,
            isCurrent: true,
          ),
          ProjectMilestone(
            id: 'm-prime-3',
            title: 'Reporting & Analytics',
            status: MilestoneStatus.pending,
          ),
        ],
        tasks: [
          ProjectTask(
            id: 't-prime-1',
            title: 'Finish liability calculations',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          ProjectTask(
            id: 't-prime-2',
            title: 'Connect asset net worth feeds',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 4)),
          ),
          ProjectTask(
            id: 't-prime-3',
            title: 'Prepare Prime v1.0 release',
            isCompleted: true,
            createdAt: now.subtract(const Duration(days: 40)),
            completedAt: now.subtract(const Duration(days: 35)),
          ),
        ],
        notes: [
          ProjectNote(
            id: 'n-prime-1',
            title: 'Liability Computation Rule',
            content: 'Amortized loan liabilities must be separated from variable revolving credit balances.',
            category: NoteCategory.architecture,
            createdAt: now.subtract(const Duration(days: 10)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),

      // 2. P² Studio
      Project(
        id: 'studio',
        name: 'P² Studio',
        description: 'Publishing engine, document workflow, and P² ecosystem studio',
        type: ProjectType.desktopApp,
        localPath: r'C:\Projects\studio',
        humanStatus: ProjectHumanStatus.active,
        priority: ProjectPriority.p0,
        currentMilestone: 'Studio v1.0 Documentation & Publishing',
        nextAction: 'Complete document update publishing flow',
        github: GitHubTelemetry(
          owner: 'psquare99',
          repo: 'studio',
          repoUrl: 'https://github.com/psquare99/studio',
          defaultBranch: 'main',
          latestCommitSha: '890713e',
          latestCommitMessage: 'docs: update Studio v1.0 documentation',
          latestCommitAuthor: 'psquare99',
          latestCommitDate: now.subtract(const Duration(days: 12)),
          recentCommitsThisWeek: 0,
          recentCommitsThisMonth: 3,
          openIssuesCount: 0,
          lastFetchedAt: now,
        ),
        milestones: [
          ProjectMilestone(
            id: 'm-studio-1',
            title: 'Studio v1.0 Documentation & Publishing',
            description: 'Finalize document update publishing lifecycle',
            status: MilestoneStatus.inProgress,
            isCurrent: true,
          ),
        ],
        tasks: [
          ProjectTask(
            id: 't-studio-1',
            title: 'Complete document update publishing flow',
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          ProjectTask(
            id: 't-studio-2',
            title: 'Verify journal publishing pipeline',
            isCompleted: true,
            createdAt: now.subtract(const Duration(days: 15)),
            completedAt: now.subtract(const Duration(days: 13)),
          ),
        ],
        notes: [
          ProjectNote(
            id: 'n-studio-1',
            title: 'Publishing Architecture Decision',
            content: 'Decoupled studio document models from downstream export formats for format agility.',
            category: NoteCategory.decision,
            createdAt: now.subtract(const Duration(days: 14)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now,
      ),

      // 3. Curio
      Project(
        id: 'curio',
        name: 'Curio',
        description: 'Knowledge discovery, bookmark repository, and thought collections',
        type: ProjectType.flutterApp,
        localPath: r'C:\Projects\curio',
        humanStatus: ProjectHumanStatus.active,
        priority: ProjectPriority.p2,
        currentMilestone: null, // Honest empty state
        nextAction: null,       // Honest empty state
        github: GitHubTelemetry(
          owner: 'psquare99',
          repo: 'curio',
          repoUrl: 'https://github.com/psquare99/curio',
          defaultBranch: 'main',
          lastFetchedAt: now,
        ),
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),

      // 4. Nook (Vault)
      Project(
        id: 'nook',
        name: 'Nook',
        description: 'Personal encrypted vault and high-privacy storage station',
        type: ProjectType.flutterApp,
        localPath: r'C:\Projects\vault',
        humanStatus: ProjectHumanStatus.active,
        priority: ProjectPriority.p2,
        currentMilestone: null,
        nextAction: null,
        github: GitHubTelemetry(
          owner: 'psquare99',
          repo: 'nook',
          repoUrl: 'https://github.com/psquare99/nook',
          defaultBranch: 'main',
          lastFetchedAt: now,
        ),
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now,
      ),

      // 5. Wayfarer
      Project(
        id: 'wayfarer',
        name: 'Wayfarer',
        description: 'Itinerary tracking, route discovery, and travel planning',
        type: ProjectType.flutterApp,
        localPath: r'C:\Projects\Wayfarer',
        humanStatus: ProjectHumanStatus.planning,
        priority: ProjectPriority.p2,
        currentMilestone: null,
        nextAction: null,
        github: GitHubTelemetry(
          owner: 'psquare99',
          repo: 'wayfarer',
          repoUrl: 'https://github.com/psquare99/wayfarer',
          defaultBranch: 'main',
          lastFetchedAt: now,
        ),
        createdAt: now.subtract(const Duration(days: 35)),
        updatedAt: now,
      ),

      // 6. WAYFINDER
      Project(
        id: 'wayfinder',
        name: 'WAYFINDER',
        description: 'Spatial navigation and wayfinding engine',
        type: ProjectType.flutterApp,
        localPath: r'C:\Projects\Wayfinder',
        humanStatus: ProjectHumanStatus.paused, // From brief: "WAYFINDER, Human status: Paused"
        priority: ProjectPriority.p2,
        currentMilestone: null,
        nextAction: null,
        github: null, // "GitHub not connected"
        createdAt: now.subtract(const Duration(days: 55)),
        updatedAt: now,
      ),

      // 7. HEARTBEAT
      Project(
        id: 'heartbeat',
        name: 'HEARTBEAT',
        description: 'System health monitoring and local process heartbeat tracker',
        type: ProjectType.systemTool,
        localPath: r'C:\Projects\heartbeat',
        humanStatus: null, // "Status not set"
        priority: ProjectPriority.none,
        currentMilestone: null,
        nextAction: null,
        github: null, // "GitHub not connected"
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),

      // 8. Harbour
      Project(
        id: 'harbour',
        name: 'Harbour',
        description: 'Container management, process docking, and port supervisor',
        type: ProjectType.systemTool,
        localPath: null,
        humanStatus: null, // "Status not set"
        priority: ProjectPriority.none,
        currentMilestone: null,
        nextAction: null,
        github: null,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
      ),

      // 9. Assets Archive
      Project(
        id: 'asset_archive',
        name: 'Assets Archive',
        description: 'Static asset indexing, media storage, and preservation archive',
        type: ProjectType.other,
        localPath: r'C:\Projects\asset_archive',
        humanStatus: null, // "Status not set"
        priority: ProjectPriority.none,
        currentMilestone: null,
        nextAction: null,
        github: null,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now,
      ),

      // 10. Gift Recommender
      Project(
        id: 'gift_recommender',
        name: 'Gift Recommender',
        description: 'Occasion intelligence and curated gift matching',
        type: ProjectType.webApp,
        localPath: null,
        humanStatus: ProjectHumanStatus.idea,
        priority: ProjectPriority.p3,
        currentMilestone: null,
        nextAction: null,
        github: null,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),

      // 11. AI Buddy Robot
      Project(
        id: 'ai_buddy_robot',
        name: 'AI Buddy Robot',
        description: 'Physical companion robot with multimodal conversational intelligence',
        type: ProjectType.hardware,
        localPath: null,
        humanStatus: ProjectHumanStatus.idea,
        priority: ProjectPriority.none,
        currentMilestone: null,
        nextAction: null,
        github: null,
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now,
      ),
    ];
  }
}
