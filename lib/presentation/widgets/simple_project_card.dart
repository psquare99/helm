import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import 'status_badge.dart';

/// Minimalist project card designed for Simple Mode.
/// Focuses purely on essential identity, authoritative status, and immediate next action.
class SimpleProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final Function(ProjectHumanStatus?)? onQuickStatusChange;

  const SimpleProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onQuickStatusChange,
  });

  @override
  State<SimpleProjectCard> createState() => _SimpleProjectCardState();
}

class _SimpleProjectCardState extends State<SimpleProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final isActive = p.humanStatus == ProjectHumanStatus.active;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? CommandColors.surfaceBase : CommandColors.surfaceCard,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isHovered
                  ? CommandColors.borderActive
                  : (isActive
                      ? CommandColors.signalEmeraldBorder
                      : CommandColors.borderSubtle),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Row 1: Type Icon, Title, Priority, Status Badge & Quick Menu
              Row(
                children: [
                  Icon(
                    p.type.icon,
                    size: 15,
                    color: isActive ? CommandColors.signalEmerald : CommandColors.signalIce,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.priority == ProjectPriority.p0 || p.priority == ProjectPriority.p1) ...[
                    PriorityBadge(priority: p.priority, compact: true),
                    const SizedBox(width: 6),
                  ],
                  HumanStatusBadge(status: p.humanStatus, compact: true),
                  if (widget.onQuickStatusChange != null) ...[
                    const SizedBox(width: 2),
                    _buildStatusMenu(context, p),
                  ],
                ],
              ),

              // Row 2: Short Description (if present)
              if (p.description != null && p.description!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Text(
                    p.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontSans,
                      fontSize: 12,
                      color: CommandColors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(height: 6),

              // Row 3: Next Action or Milestone Callout
              _buildNextActionArea(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextActionArea(Project p) {
    if (p.nextAction != null && p.nextAction!.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: CommandColors.signalIceSoft,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: CommandColors.signalIceBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 12,
              color: CommandColors.signalIce,
            ),
            const SizedBox(width: 6),
            const Text(
              'NEXT: ',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: CommandColors.signalIce,
              ),
            ),
            Expanded(
              child: Text(
                p.nextAction!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CommandColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (p.currentMilestone != null && p.currentMilestone!.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: CommandColors.background,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: CommandColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 12,
              color: CommandColors.signalAmber,
            ),
            const SizedBox(width: 6),
            const Text(
              'MILESTONE: ',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: CommandColors.signalAmber,
              ),
            ),
            Expanded(
              child: Text(
                p.currentMilestone!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 12,
                  color: CommandColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CommandColors.background,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.radio_button_unchecked_rounded,
            size: 11,
            color: CommandColors.textMuted,
          ),
          SizedBox(width: 6),
          Text(
            'No next action defined',
            style: TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: CommandColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMenu(BuildContext context, Project p) {
    return PopupMenuButton<ProjectHumanStatus?>(
      tooltip: 'Change status',
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 14,
        color: CommandColors.textMuted,
      ),
      onSelected: (status) {
        widget.onQuickStatusChange?.call(status);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<ProjectHumanStatus?>(
          value: null,
          child: Text('Clear status (Not Set)', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuDivider(),
        ...ProjectHumanStatus.values.map(
          (status) => PopupMenuItem<ProjectHumanStatus?>(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: p.humanStatus == status ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
