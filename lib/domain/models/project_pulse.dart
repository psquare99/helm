import 'package:intl/intl.dart';
import 'project.dart';
import 'project_status.dart';

/// Presentation view model for the concise Project Pulse.
/// Designed for instant glanceability: "I know where it stands."
class ProjectPulseData {
  final String projectId;
  final String projectName;
  final ProjectHumanStatus? humanStatus;
  final String humanStatusText;
  final String milestoneText;
  final bool hasMilestone;
  final String nextActionText;
  final bool hasNextAction;
  final ObservedActivity observedActivity;
  final String observedActivityText;
  final String lastActivityText;
  final String recentActivityText;
  final int? openIssuesCount;
  final String? latestCommitMessage;
  final String? latestCommitSha;
  final bool isGithubConnected;
  final int pendingTasks;

  const ProjectPulseData({
    required this.projectId,
    required this.projectName,
    required this.humanStatus,
    required this.humanStatusText,
    required this.milestoneText,
    required this.hasMilestone,
    required this.nextActionText,
    required this.hasNextAction,
    required this.observedActivity,
    required this.observedActivityText,
    required this.lastActivityText,
    required this.recentActivityText,
    required this.openIssuesCount,
    required this.latestCommitMessage,
    required this.latestCommitSha,
    required this.isGithubConnected,
    required this.pendingTasks,
  });

  factory ProjectPulseData.fromProject(Project project) {
    final gh = project.github;
    final isConnected = gh != null;
    final observed = project.effectiveObservedActivity;

    String lastActivity;
    String recentActivity;

    if (!isConnected) {
      lastActivity = 'Untracked';
      recentActivity = 'GitHub not connected';
    } else if (gh.latestCommitDate != null) {
      final now = DateTime.now();
      final diff = now.difference(gh.latestCommitDate!);
      if (diff.inHours < 24 && now.day == gh.latestCommitDate!.day) {
        lastActivity = 'Today';
      } else if (diff.inDays == 1 || (diff.inHours < 48 && now.day != gh.latestCommitDate!.day)) {
        lastActivity = 'Yesterday';
      } else if (diff.inDays < 7) {
        lastActivity = '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        lastActivity = '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
      } else {
        lastActivity = DateFormat('MMM d, yyyy').format(gh.latestCommitDate!);
      }

      if (gh.recentCommitsThisWeek > 0) {
        recentActivity =
            '${gh.recentCommitsThisWeek} commit${gh.recentCommitsThisWeek == 1 ? "" : "s"} this week';
      } else if (gh.recentCommitsThisMonth > 0) {
        recentActivity =
            '${gh.recentCommitsThisMonth} commit${gh.recentCommitsThisMonth == 1 ? "" : "s"} this month';
      } else if (gh.recentCommits.isNotEmpty) {
        recentActivity = 'Recent commits on ${gh.defaultBranch}';
      } else {
        recentActivity = 'No recent commits';
      }
    } else {
      lastActivity = 'No recorded commits';
      recentActivity = 'No recent activity';
    }

    return ProjectPulseData(
      projectId: project.id,
      projectName: project.name,
      humanStatus: project.humanStatus,
      humanStatusText: project.statusDisplay,
      milestoneText: project.milestoneDisplay,
      hasMilestone: project.hasMilestone,
      nextActionText: project.nextActionDisplay,
      hasNextAction: project.hasNextAction,
      observedActivity: observed,
      observedActivityText: observed.label,
      lastActivityText: lastActivity,
      recentActivityText: recentActivity,
      openIssuesCount: isConnected ? gh.openIssuesCount : null,
      latestCommitMessage: gh?.latestCommitMessage,
      latestCommitSha: gh?.shortLatestSha,
      isGithubConnected: isConnected,
      pendingTasks: project.pendingTasksCount,
    );
  }
}
