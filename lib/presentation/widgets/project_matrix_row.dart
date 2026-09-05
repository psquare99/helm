import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_pulse.dart';
import '../../domain/models/project_status.dart';
import 'status_badge.dart';

class ProjectMatrixRow extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final Function(ProjectHumanStatus?)? onQuickStatusChange;

  const ProjectMatrixRow({
    super.key,
    required this.project,
    required this.onTap,
    this.onQuickStatusChange,
  });

  @override
  State<ProjectMatrixRow> createState() => _ProjectMatrixRowState();
}

class _ProjectMatrixRowState extends State<ProjectMatrixRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final pulse = ProjectPulseData.fromProject(p);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? CommandColors.surfaceRaised : CommandColors.surfaceBase,
            border: Border(
              bottom: const BorderSide(color: CommandColors.borderSubtle, width: 1),
              left: BorderSide(
                color: p.humanStatus == ProjectHumanStatus.active
                    ? CommandColors.signalEmerald
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // 1. Project Identifier & Priority (Width: 180)
              SizedBox(
                width: 180,
                child: Row(
                  children: [
                    Icon(p.type.icon, size: 14, color: CommandColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontSans,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CommandColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    PriorityBadge(priority: p.priority, compact: true),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // 2. Human Status (Width: 120)
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: HumanStatusBadge(status: p.humanStatus, compact: true),
                ),
              ),

              const SizedBox(width: 12),

              // 3. Observed Activity (Width: 140)
              SizedBox(
                width: 140,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ObservedActivityBadge(
                    activity: pulse.observedActivity,
                    compact: true,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 4. Milestone (Width: 180)
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pulse.milestoneText,
                      style: TextStyle(
                        fontFamily: pulse.hasMilestone
                            ? CommandTheme.fontSans
                            : CommandTheme.fontMono,
                        fontSize: 12,
                        fontWeight: pulse.hasMilestone ? FontWeight.w600 : FontWeight.w400,
                        color: pulse.hasMilestone
                            ? CommandColors.signalIce
                            : CommandColors.textDisabled,
                        fontStyle: pulse.hasMilestone ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // 5. Next Action (Flexible)
              Expanded(
                child: Text(
                  pulse.nextActionText,
                  style: TextStyle(
                    fontFamily: pulse.hasNextAction
                        ? CommandTheme.fontSans
                        : CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: pulse.hasNextAction ? FontWeight.w500 : FontWeight.w400,
                    color: pulse.hasNextAction
                        ? CommandColors.textPrimary
                        : CommandColors.textDisabled,
                    fontStyle: pulse.hasNextAction ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 16),

              // 6. Last Activity & Telemetry (Width: 130)
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pulse.lastActivityText,
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CommandColors.textMuted,
                      ),
                    ),
                    if (pulse.latestCommitSha != null)
                      Text(
                        pulse.latestCommitSha!,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 10,
                          color: CommandColors.textDisabled,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Actions
              PopupMenuButton<ProjectHumanStatus?>(
                tooltip: 'Update Status',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 15,
                  color: CommandColors.textMuted,
                ),
                color: CommandColors.surfaceBase,
                onSelected: (status) => widget.onQuickStatusChange?.call(status),
                itemBuilder: (context) => [
                  const PopupMenuItem<ProjectHumanStatus?>(
                    value: null,
                    height: 30,
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
                      height: 30,
                      child: Text(
                        s.label,
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 11,
                          color: p.humanStatus == s ? s.color : CommandColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
