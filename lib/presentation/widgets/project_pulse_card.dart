import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_pulse.dart';
import '../../domain/models/project_status.dart';
import 'status_badge.dart';

class ProjectPulseCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final Function(ProjectHumanStatus?)? onQuickStatusChange;

  const ProjectPulseCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onQuickStatusChange,
  });

  @override
  State<ProjectPulseCard> createState() => _ProjectPulseCardState();
}

class _ProjectPulseCardState extends State<ProjectPulseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final pulse = ProjectPulseData.fromProject(widget.project);
    final p = widget.project;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _isHovered ? CommandColors.surfaceBase : CommandColors.surfaceCard,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isHovered
                  ? CommandColors.borderActive
                  : (p.humanStatus == ProjectHumanStatus.active
                      ? CommandColors.signalEmeraldBorder
                      : CommandColors.borderSubtle),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Title & Type Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? CommandColors.surfaceRaised
                      : CommandColors.surfaceBase,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: CommandColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      p.type.icon,
                      size: 14,
                      color: CommandColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontSans,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: CommandColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PriorityBadge(priority: p.priority, compact: true),
                    const SizedBox(width: 6),
                    _buildStatusMenu(context, p),
                  ],
                ),
              ),

              // Status & Signal Telemetry Band
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  color: CommandColors.surfaceCard,
                  border: Border(
                    bottom: BorderSide(color: CommandColors.borderSubtle, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    HumanStatusBadge(status: p.humanStatus, compact: true),
                    const SizedBox(width: 8),
                    ObservedActivityBadge(activity: pulse.observedActivity, compact: true),
                    const Spacer(),
                    if (pulse.isGithubConnected && pulse.openIssuesCount != null) ...[
                      Tooltip(
                        message: '${pulse.openIssuesCount} open issues',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.adjust_rounded,
                              size: 11,
                              color: CommandColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pulse.openIssuesCount}',
                              style: const TextStyle(
                                fontFamily: CommandTheme.fontMono,
                                fontSize: 10.5,
                                color: CommandColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (p.pendingTasksCount > 0)
                      Tooltip(
                        message: '${p.pendingTasksCount} pending tasks',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 12,
                              color: CommandColors.signalAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${p.pendingTasksCount}',
                              style: const TextStyle(
                                fontFamily: CommandTheme.fontMono,
                                fontSize: 10.5,
                                color: CommandColors.signalAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Core Telemetry Body: Milestone + Next Action
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Milestone
                    _buildFieldRow(
                      label: 'MILESTONE',
                      value: pulse.milestoneText,
                      isDefined: pulse.hasMilestone,
                      highlightColor: CommandColors.signalIce,
                    ),
                    const SizedBox(height: 9),
                    // Next Action
                    _buildFieldRow(
                      label: 'NEXT ACTION',
                      value: pulse.nextActionText,
                      isDefined: pulse.hasNextAction,
                      highlightColor: CommandColors.signalEmerald,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Repository Telemetry Readout Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  color: CommandColors.surfaceRaised,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                  border: Border(
                    top: BorderSide(color: CommandColors.borderSubtle, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      pulse.isGithubConnected ? Icons.commit_rounded : Icons.link_off_rounded,
                      size: 13,
                      color: pulse.isGithubConnected
                          ? CommandColors.textMuted
                          : CommandColors.textDisabled,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pulse.isGithubConnected
                            ? (pulse.latestCommitMessage != null
                                ? '${pulse.latestCommitSha ?? ""} ${pulse.latestCommitMessage!}'
                                : pulse.recentActivityText)
                            : 'GitHub not connected',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 10.5,
                          color: pulse.isGithubConnected
                              ? CommandColors.textSecondary
                              : CommandColors.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pulse.lastActivityText,
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10.5,
                        color: CommandColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String value,
    required bool isDefined,
    required Color highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: CommandTheme.fontMono,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: CommandColors.textMuted,
          ),
        ),
        const SizedBox(height: 2.5),
        Text(
          value,
          style: TextStyle(
            fontFamily: isDefined ? CommandTheme.fontSans : CommandTheme.fontMono,
            fontSize: 12.5,
            fontWeight: isDefined ? FontWeight.w600 : FontWeight.w400,
            color: isDefined ? CommandColors.textPrimary : CommandColors.textDisabled,
            fontStyle: isDefined ? FontStyle.normal : FontStyle.italic,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusMenu(BuildContext context, Project p) {
    return PopupMenuButton<ProjectHumanStatus?>(
      tooltip: 'Quick Status Change',
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 15,
        color: CommandColors.textMuted,
      ),
      color: CommandColors.surfaceBase,
      onSelected: (status) {
        widget.onQuickStatusChange?.call(status);
      },
      itemBuilder: (context) {
        return [
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
                      fontWeight:
                          p.humanStatus == s ? FontWeight.w700 : FontWeight.w400,
                      color: p.humanStatus == s ? s.color : CommandColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
