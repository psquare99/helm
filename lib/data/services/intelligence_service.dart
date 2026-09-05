import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/project_intelligence.dart';

/// Intelligence observation engine that analyzes project state,
/// observed external activity, pending milestones, and tasks.
class IntelligenceService {
  List<ProjectObservation> generateObservations(List<Project> projects) {
    final observations = <ProjectObservation>[];
    final now = DateTime.now();

    // 1. High Momentum Synthesis
    final activeWithCommits = projects.where((p) =>
        p.humanStatus == ProjectHumanStatus.active &&
        p.github != null &&
        (p.effectiveObservedActivity == ObservedActivity.veryActive ||
            p.effectiveObservedActivity == ObservedActivity.active));

    for (final p in activeWithCommits) {
      final gh = p.github!;
      observations.add(ProjectObservation(
        id: 'momentum-${p.id}',
        projectId: p.id,
        projectName: p.name,
        type: ObservationType.momentum,
        title: '${p.name} has active momentum',
        description:
            'Observed ${gh.recentCommitsThisWeek > 0 ? "${gh.recentCommitsThisWeek} commits this week" : "recent commits"}. Latest: "${gh.latestCommitMessage ?? "updates"}" (${gh.shortLatestSha}).',
        timestamp: now,
        actionableHint: p.nextAction != null
            ? 'Next action: ${p.nextAction}'
            : 'No next action defined. Consider assigning a next step.',
      ));
    }

    // 2. Active Projects Missing Next Action
    final activeMissingAction = projects.where((p) =>
        p.humanStatus == ProjectHumanStatus.active && !p.hasNextAction);

    for (final p in activeMissingAction) {
      observations.add(ProjectObservation(
        id: 'missing-action-${p.id}',
        projectId: p.id,
        projectName: p.name,
        type: ObservationType.attention,
        title: '${p.name} is Active but has no next action',
        description:
            'Declared status is Active, but no immediate next action or pending task is defined to drive momentum.',
        timestamp: now,
        actionableHint: 'Define a specific next action to keep focus clear.',
      ));
    }

    // 3. Current Milestone with Unfinished Tasks
    for (final p in projects) {
      if (p.milestones.any((m) => m.isCurrent) && p.pendingTasksCount > 0) {
        final currentMilestone = p.milestones.firstWhere((m) => m.isCurrent);
        observations.add(ProjectObservation(
          id: 'milestone-progress-${p.id}',
          projectId: p.id,
          projectName: p.name,
          type: ObservationType.milestoneProgress,
          title: '${p.name}: Milestone "${currentMilestone.title}"',
          description:
              'Current milestone has ${p.pendingTasksCount} pending task${p.pendingTasksCount == 1 ? "" : "s"}.',
          timestamp: now,
          actionableHint: p.nextAction != null
              ? 'Focus on: ${p.nextAction}'
              : 'Advance milestone tasks.',
        ));
      }
    }

    // 4. Paused or Stale Projects
    final pausedProjects = projects.where((p) => p.humanStatus == ProjectHumanStatus.paused);
    for (final p in pausedProjects) {
      observations.add(ProjectObservation(
        id: 'paused-${p.id}',
        projectId: p.id,
        projectName: p.name,
        type: ObservationType.untracked,
        title: '${p.name} is paused',
        description:
            'Human status is Paused. External activity: ${p.effectiveObservedActivity.label}.',
        timestamp: now,
      ));
    }

    // 5. Focus Recommendation: "What should I work on next?"
    final topPriorityActive = projects
        .where((p) =>
            p.humanStatus == ProjectHumanStatus.active &&
            p.priority == ProjectPriority.p0 &&
            p.hasNextAction)
        .firstOrNull ??
        projects
            .where((p) =>
                p.humanStatus == ProjectHumanStatus.active &&
                p.priority == ProjectPriority.p1 &&
                p.hasNextAction)
            .firstOrNull;

    if (topPriorityActive != null) {
      observations.insert(
        0,
        ProjectObservation(
          id: 'recommendation-${topPriorityActive.id}',
          projectId: topPriorityActive.id,
          projectName: topPriorityActive.name,
          type: ObservationType.recommendation,
          title: 'Prime Focus: ${topPriorityActive.name}',
          description:
              'Highest priority active project (${topPriorityActive.priority.short}). Immediate next action: "${topPriorityActive.nextActionDisplay}".',
          timestamp: now,
          actionableHint: 'Open ${topPriorityActive.name} to continue execution.',
        ),
      );
    }

    return observations;
  }
}
