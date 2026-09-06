import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/project_milestone.dart';
import '../../domain/models/project_note.dart';
import '../../domain/models/project_pulse.dart';
import '../state/project_manager_controller.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state_view.dart';
import 'project_editor_dialog.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final ProjectManagerController controller;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.controller,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late TextEditingController _newTaskController;
  late TextEditingController _nextActionController;
  late TextEditingController _milestoneController;

  bool _isEditingNextAction = false;
  bool _isEditingMilestone = false;

  @override
  void initState() {
    super.initState();
    _newTaskController = TextEditingController();
    _nextActionController = TextEditingController();
    _milestoneController = TextEditingController();
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    _nextActionController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  Project? _getProject() {
    return widget.controller.projects
        .where((p) => p.id == widget.projectId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final project = _getProject();
        if (project == null) {
          return Scaffold(
            backgroundColor: CommandColors.background,
            appBar: AppBar(
              backgroundColor: CommandColors.surfaceBase,
              title: const Text('PROJECT NOT FOUND'),
            ),
            body: const Center(
              child: Text(
                'This project may have been deleted.',
                style: TextStyle(color: CommandColors.textMuted),
              ),
            ),
          );
        }

        final pulse = ProjectPulseData.fromProject(project);

        return Scaffold(
          backgroundColor: CommandColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Mission Control Header
                _buildTopBar(context, project),

              // Main Body Columns
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 950;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Rail: Telemetry & Repository & Notes (420px)
                          SizedBox(
                            width: 420,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildPulseTelemetryCard(project, pulse),
                                  const SizedBox(height: 16),
                                  _buildGitHubTelemetryPanel(project),
                                  const SizedBox(height: 16),
                                  _buildNotesPanel(project),
                                ],
                              ),
                            ),
                          ),

                          const VerticalDivider(
                            width: 1,
                            color: CommandColors.borderSubtle,
                          ),

                          // Right Area: Focus, Milestones & Task Execution Deck
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCurrentFocusCard(project, pulse),
                                  const SizedBox(height: 20),
                                  _buildTasksCard(project),
                                  const SizedBox(height: 20),
                                  _buildMilestonesCard(project),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Stacked view for narrow screen
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPulseTelemetryCard(project, pulse),
                            const SizedBox(height: 16),
                            _buildCurrentFocusCard(project, pulse),
                            const SizedBox(height: 16),
                            _buildTasksCard(project),
                            const SizedBox(height: 16),
                            _buildMilestonesCard(project),
                            const SizedBox(height: 16),
                            _buildGitHubTelemetryPanel(project),
                            const SizedBox(height: 16),
                            _buildNotesPanel(project),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _buildTopBar(BuildContext context, Project project) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: 10,
          ),
          decoration: const BoxDecoration(
            color: CommandColors.surfaceBase,
            border: Border(
              bottom: BorderSide(color: CommandColors.borderSubtle, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Return to Portfolio Dashboard',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: CommandColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: CommandColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Project Title & Type
              Icon(project.type.icon, size: 18, color: CommandColors.signalIce),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  project.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: CommandColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: CommandColors.borderSubtle),
                ),
                child: Text(
                  project.type.label,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 9.5,
                    color: CommandColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Telemetry refresh for this single project
              if (project.github != null) ...[
                if (isMobile)
                  IconButton(
                    tooltip: 'Poll observed GitHub telemetry',
                    onPressed: () =>
                        widget.controller.refreshSingleProjectTelemetry(project.id),
                    icon: const Icon(Icons.sync_rounded, size: 16, color: CommandColors.signalIce),
                    style: IconButton.styleFrom(
                      backgroundColor: CommandColors.surfaceCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: CommandColors.borderSubtle),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.controller.refreshSingleProjectTelemetry(project.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CommandColors.borderMedium),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 13, color: CommandColors.signalIce),
                    label: const Text(
                      'POLL SIGNALS',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: CommandColors.textPrimary,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],

              const Spacer(),

              // Edit Project
              IconButton(
            tooltip: 'Configure Project Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ProjectEditorDialog(
                  initialProject: project,
                  onSave: (updated) => widget.controller.updateProject(updated),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: CommandColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: CommandColors.borderSubtle),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Delete Project
          IconButton(
            tooltip: 'Remove Project from Portfolio',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: CommandColors.surfaceCard,
                  title: Text('Delete ${project.name}?'),
                  content: const Text(
                    'Are you sure you want to remove this project from Helm? Local files will not be affected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: CommandColors.signalCoral,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await widget.controller.deleteProject(project.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: CommandColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: CommandColors.borderSubtle),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildPulseTelemetryCard(Project project, ProjectPulseData pulse) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            ),
            child: const Row(
              children: [
                Icon(Icons.monitor_heart_rounded, size: 14, color: CommandColors.signalIce),
                SizedBox(width: 8),
                Text(
                  'PROJECT PULSE // STATUS vs SIGNAL',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description != null && project.description!.isNotEmpty) ...[
                  Text(
                    project.description!,
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontSans,
                      fontSize: 12.5,
                      color: CommandColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: CommandColors.borderSubtle),
                  const SizedBox(height: 14),
                ],

                // 1. Authoritative Human Status
                const Text(
                  'HUMAN-DEFINED STATE (AUTHORITATIVE)',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    HumanStatusBadge(status: project.humanStatus),
                    const SizedBox(width: 10),
                    // Quick change dropdown button
                    PopupMenuButton<ProjectHumanStatus?>(
                      tooltip: 'Change State',
                      color: CommandColors.surfaceCard,
                      onSelected: (status) =>
                          widget.controller.updateHumanStatus(project.id, status),
                      itemBuilder: (context) => [
                        const PopupMenuItem<ProjectHumanStatus?>(
                          value: null,
                          height: 32,
                          child: Text(
                            'Status not set',
                            style: TextStyle(
                              fontFamily: CommandTheme.fontMono,
                              fontSize: 11,
                              color: CommandColors.textMuted,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        ...ProjectHumanStatus.values.map(
                          (s) => PopupMenuItem<ProjectHumanStatus?>(
                            value: s,
                            height: 32,
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.label,
                                  style: TextStyle(
                                    fontFamily: CommandTheme.fontMono,
                                    fontSize: 11,
                                    color: project.humanStatus == s
                                        ? s.color
                                        : CommandColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CommandColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CommandColors.borderSubtle),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MODIFY',
                              style: TextStyle(
                                fontFamily: CommandTheme.fontMono,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: CommandColors.signalIce,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 14, color: CommandColors.signalIce),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Observed Activity Telemetry
                const Text(
                  'OBSERVED EXTERNAL SIGNAL',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                ObservedActivityBadge(activity: pulse.observedActivity),

                const SizedBox(height: 14),

                // 3. Priority
                const Text(
                  'PRIORITY LEVEL',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PriorityBadge(priority: project.priority),
                    const SizedBox(width: 8),
                    PopupMenuButton<ProjectPriority>(
                      tooltip: 'Set Priority',
                      color: CommandColors.surfaceCard,
                      onSelected: (p) => widget.controller.updatePriority(project.id, p),
                      itemBuilder: (context) => ProjectPriority.values.map(
                        (pr) => PopupMenuItem(
                          value: pr,
                          height: 32,
                          child: Text(
                            pr.label,
                            style: TextStyle(
                              fontFamily: CommandTheme.fontMono,
                              fontSize: 11,
                              color: pr.color,
                            ),
                          ),
                        ),
                      ).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CommandColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CommandColors.borderSubtle),
                        ),
                        child: Text(
                          project.priority.label,
                          style: const TextStyle(
                            fontFamily: CommandTheme.fontMono,
                            fontSize: 10.5,
                            color: CommandColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Local Path
                if (project.localPath != null && project.localPath!.isNotEmpty) ...[
                  const Text(
                    'LOCAL SYSTEM PATH',
                    style: TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: CommandColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: CommandColors.surfaceBase,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: CommandColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_rounded, size: 14, color: CommandColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.localPath!,
                            style: const TextStyle(
                              fontFamily: CommandTheme.fontMono,
                              fontSize: 11,
                              color: CommandColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubTelemetryPanel(Project project) {
    final gh = project.github;
    final isConnected = gh != null;

    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.source_rounded, size: 14, color: CommandColors.signalIce),
                const SizedBox(width: 8),
                const Text(
                  'GITHUB TELEMETRY',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isConnected && gh.repoUrl != null)
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(gh.repoUrl!)),
                    child: const Row(
                      children: [
                        Text(
                          'OPEN REPO',
                          style: TextStyle(
                            fontFamily: CommandTheme.fontMono,
                            fontSize: 10,
                            color: CommandColors.signalIce,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new_rounded, size: 11, color: CommandColors.signalIce),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (!isConnected) ...[
            const EmptyStateView(
              icon: Icons.link_off_rounded,
              title: 'GitHub not connected',
              subtitle: 'Link a repository in project settings to track commits and activity signals.',
              compact: true,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Repo name and branch
                  Row(
                    children: [
                      const Icon(Icons.code_rounded, size: 14, color: CommandColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        gh.fullName,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CommandColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: CommandColors.surfaceBase,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          gh.defaultBranch,
                          style: const TextStyle(
                            fontFamily: CommandTheme.fontMono,
                            fontSize: 10,
                            color: CommandColors.signalIce,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Telemetry metrics
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'THIS WEEK',
                        value: '${gh.recentCommitsThisWeek}',
                        unit: 'commits',
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        label: 'THIS MONTH',
                        value: '${gh.recentCommitsThisMonth}',
                        unit: 'commits',
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        label: 'OPEN ISSUES',
                        value: '${gh.openIssuesCount}',
                        unit: 'issues',
                      ),
                    ],
                  ),

                  if (gh.lastFetchError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CommandColors.signalCoralSoft,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: CommandColors.signalCoralBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: CommandColors.signalCoral),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              gh.lastFetchError!,
                              style: const TextStyle(
                                fontFamily: CommandTheme.fontSans,
                                fontSize: 11,
                                color: CommandColors.signalCoral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Recent Commits List
                  if (gh.recentCommits.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'RECENT COMMITS',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: CommandColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...gh.recentCommits.take(5).map((commit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CommandColors.surfaceBase,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: CommandColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    commit.shortSha,
                                    style: const TextStyle(
                                      fontFamily: CommandTheme.fontMono,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: CommandColors.signalIce,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      commit.author,
                                      style: const TextStyle(
                                        fontFamily: CommandTheme.fontMono,
                                        fontSize: 10,
                                        color: CommandColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                commit.message,
                                style: const TextStyle(
                                  fontFamily: CommandTheme.fontSans,
                                  fontSize: 11.5,
                                  color: CommandColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: CommandColors.surfaceBase,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CommandColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: CommandColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 9,
                    color: CommandColors.textDisabled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFocusCard(Project project, ProjectPulseData pulse) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: project.humanStatus == ProjectHumanStatus.active
              ? CommandColors.signalEmeraldBorder
              : CommandColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: CommandColors.signalAmber),
                SizedBox(width: 8),
                Text(
                  'CURRENT WORK // EXECUTION FOCUS',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Current Milestone
                Row(
                  children: [
                    const Text(
                      'CURRENT MILESTONE',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: CommandColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isEditingMilestone ? Icons.check_rounded : Icons.edit_outlined,
                        size: 14,
                        color: CommandColors.signalIce,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (_isEditingMilestone) {
                          widget.controller.updateMilestone(
                            project.id,
                            _milestoneController.text,
                          );
                          setState(() => _isEditingMilestone = false);
                        } else {
                          _milestoneController.text = project.currentMilestone ?? '';
                          setState(() => _isEditingMilestone = true);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isEditingMilestone) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _milestoneController,
                          style: const TextStyle(
                            fontFamily: CommandTheme.fontSans,
                            fontSize: 13,
                            color: CommandColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter current milestone name...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() => _isEditingMilestone = false),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    pulse.milestoneText,
                    style: TextStyle(
                      fontFamily: pulse.hasMilestone
                          ? CommandTheme.fontSans
                          : CommandTheme.fontMono,
                      fontSize: 15,
                      fontWeight: pulse.hasMilestone ? FontWeight.w700 : FontWeight.w400,
                      color: pulse.hasMilestone
                          ? CommandColors.signalIce
                          : CommandColors.textDisabled,
                      fontStyle: pulse.hasMilestone ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                const Divider(height: 1, color: CommandColors.borderSubtle),
                const SizedBox(height: 18),

                // 2. Next Action
                Row(
                  children: [
                    const Text(
                      'IMMEDIATE NEXT ACTION',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: CommandColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isEditingNextAction ? Icons.check_rounded : Icons.edit_outlined,
                        size: 14,
                        color: CommandColors.signalEmerald,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (_isEditingNextAction) {
                          widget.controller.updateNextAction(
                            project.id,
                            _nextActionController.text,
                          );
                          setState(() => _isEditingNextAction = false);
                        } else {
                          _nextActionController.text = project.nextAction ?? '';
                          setState(() => _isEditingNextAction = true);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isEditingNextAction) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nextActionController,
                          style: const TextStyle(
                            fontFamily: CommandTheme.fontSans,
                            fontSize: 13,
                            color: CommandColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter next immediate action...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() => _isEditingNextAction = false),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    pulse.nextActionText,
                    style: TextStyle(
                      fontFamily: pulse.hasNextAction
                          ? CommandTheme.fontSans
                          : CommandTheme.fontMono,
                      fontSize: 15,
                      fontWeight: pulse.hasNextAction ? FontWeight.w600 : FontWeight.w400,
                      color: pulse.hasNextAction
                          ? CommandColors.textPrimary
                          : CommandColors.textDisabled,
                      fontStyle: pulse.hasNextAction ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(Project project) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: CommandColors.signalEmerald),
                const SizedBox(width: 8),
                const Text(
                  'PROJECT TASKS',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${project.completedTasksCount} / ${project.tasks.length} DONE',
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 11,
                    color: CommandColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Quick add task field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTaskController,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontSans,
                          fontSize: 13,
                          color: CommandColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Add a new task or action item...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            widget.controller.addTask(project.id, val);
                            _newTaskController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final val = _newTaskController.text;
                        if (val.trim().isNotEmpty) {
                          widget.controller.addTask(project.id, val);
                          _newTaskController.clear();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: CommandColors.surfaceRaised,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(color: CommandColors.borderSubtle),
                      ),
                      child: const Text(
                        'ADD',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CommandColors.signalEmerald,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (project.tasks.isEmpty) ...[
                  const EmptyStateView(
                    icon: Icons.checklist_rounded,
                    title: 'No tasks defined yet',
                    subtitle: 'Add actionable items above to establish momentum.',
                    compact: true,
                  ),
                ] else ...[
                  ...project.tasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: CommandColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: CommandColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              activeColor: CommandColors.signalEmerald,
                              checkColor: Colors.white,
                              side: const BorderSide(color: CommandColors.borderMedium),
                              onChanged: (_) =>
                                  widget.controller.toggleTask(project.id, task.id),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontFamily: CommandTheme.fontSans,
                                  fontSize: 13,
                                  color: task.isCompleted
                                      ? CommandColors.textDisabled
                                      : CommandColors.textPrimary,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 15),
                              color: CommandColors.textMuted,
                              onPressed: () =>
                                  widget.controller.deleteTask(project.id, task.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard(Project project) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, size: 16, color: CommandColors.signalIce),
                const SizedBox(width: 8),
                const Text(
                  'PROJECT MILESTONES',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showAddMilestoneDialog(context, project),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CommandColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  icon: const Icon(Icons.add, size: 13, color: CommandColors.signalIce),
                  label: const Text(
                    'ADD MILESTONE',
                    style: TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CommandColors.signalIce,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: project.milestones.isEmpty
                ? const EmptyStateView(
                    icon: Icons.flag_outlined,
                    title: 'No milestones yet',
                    subtitle: 'Milestones anchor long-term development targets and tracks.',
                    compact: true,
                  )
                : Column(
                    children: project.milestones.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CommandColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: m.isCurrent
                                  ? CommandColors.signalIce.withValues(alpha: 0.35)
                                  : CommandColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                m.status == MilestoneStatus.completed
                                    ? Icons.check_circle_rounded
                                    : (m.isCurrent
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked),
                                size: 16,
                                color: m.status == MilestoneStatus.completed
                                    ? CommandColors.signalEmerald
                                    : (m.isCurrent
                                        ? CommandColors.signalIce
                                        : CommandColors.textDisabled),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          m.title,
                                          style: const TextStyle(
                                            fontFamily: CommandTheme.fontSans,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: CommandColors.textPrimary,
                                          ),
                                        ),
                                        if (m.isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: CommandColors.signalIce
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              'CURRENT',
                                              style: TextStyle(
                                                fontFamily: CommandTheme.fontMono,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: CommandColors.signalIce,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (m.description != null &&
                                        m.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        m.description!,
                                        style: const TextStyle(
                                          fontFamily: CommandTheme.fontSans,
                                          fontSize: 11.5,
                                          color: CommandColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => widget.controller
                                    .toggleMilestoneCurrent(project.id, m.id),
                                child: Text(
                                  m.isCurrent ? 'ACTIVE' : 'SET CURRENT',
                                  style: TextStyle(
                                    fontFamily: CommandTheme.fontMono,
                                    fontSize: 10,
                                    color: m.isCurrent
                                        ? CommandColors.signalIce
                                        : CommandColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesPanel(Project project) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, size: 14, color: CommandColors.signalAmber),
                const SizedBox(width: 8),
                const Text(
                  'NOTES & DECISIONS',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 15, color: CommandColors.signalAmber),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAddNoteDialog(context, project),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: project.notes.isEmpty
                ? const EmptyStateView(
                    icon: Icons.edit_note_rounded,
                    title: 'No notes or decisions yet',
                    subtitle: 'Record architectural choices and rationale.',
                    compact: true,
                  )
                : Column(
                    children: project.notes.map((n) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CommandColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: CommandColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(n.category.icon, size: 12, color: n.category.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    n.category.label.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: CommandTheme.fontMono,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: n.category.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: const TextStyle(
                                        fontFamily: CommandTheme.fontSans,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: CommandColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 13),
                                    color: CommandColors.textMuted,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        widget.controller.deleteNote(project.id, n.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.content,
                                style: const TextStyle(
                                  fontFamily: CommandTheme.fontSans,
                                  fontSize: 11.5,
                                  color: CommandColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, Project project) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CommandColors.surfaceCard,
        title: const Text('Add Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: 'Milestone Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                widget.controller.addMilestone(
                  project.id,
                  ProjectMilestone(
                    id: 'm-${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  ),
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, Project project) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    NoteCategory category = NoteCategory.note;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CommandColors.surfaceCard,
          title: const Text('Add Note or Decision'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NoteCategory>(
                initialValue: category,
                dropdownColor: CommandColors.surfaceCard,
                items: NoteCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => category = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Content or rationale...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  widget.controller.addNote(
                    project.id,
                    ProjectNote(
                      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      category: category,
                      createdAt: DateTime.now(),
                    ),
                  );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
