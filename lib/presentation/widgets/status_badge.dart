import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project_status.dart';

/// Human status indicator pill (Minimal, Calm Light Styling)
class HumanStatusBadge extends StatelessWidget {
  final ProjectHumanStatus? status;
  final bool compact;

  const HumanStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: CommandColors.surfaceRaised,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: CommandColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: CommandColors.textDisabled,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'STATUS NOT SET',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: CommandColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final s = status!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: s.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: s.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? s.code : s.label.toUpperCase(),
            style: TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: s.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Observed external activity indicator pill (Minimal Light Styling)
class ObservedActivityBadge extends StatelessWidget {
  final ObservedActivity activity;
  final bool compact;

  const ObservedActivityBadge({
    super.key,
    required this.activity,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUntracked = activity == ObservedActivity.notConnected;
    final color = isUntracked ? CommandColors.textMuted : activity.color;

    return Tooltip(
      message: activity.detail,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: isUntracked
              ? CommandColors.surfaceRaised
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isUntracked
                ? CommandColors.borderSubtle
                : color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUntracked
                  ? Icons.cloud_off_rounded
                  : Icons.sensors_rounded,
              size: compact ? 10 : 12,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              compact
                  ? (isUntracked ? 'OFFLINE' : activity.code)
                  : activity.label.toUpperCase(),
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Project priority pill
class PriorityBadge extends StatelessWidget {
  final ProjectPriority priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (priority == ProjectPriority.none) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 1.5 : 3,
      ),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: priority.color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        priority.short,
        style: TextStyle(
          fontFamily: CommandTheme.fontMono,
          fontSize: compact ? 9.5 : 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: priority.color,
        ),
      ),
    );
  }
}
