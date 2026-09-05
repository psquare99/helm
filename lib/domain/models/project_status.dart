import 'package:flutter/material.dart';

/// Human-defined authoritative state of a project.
/// This state is declared by the user and is NEVER automatically overwritten
/// by external activity or GitHub signals.
enum ProjectHumanStatus {
  idea(
    label: 'Idea',
    code: 'IDEA',
    color: Color(0xFF94A3B8), // Slate
    description: 'Concept or exploration phase, not yet in development',
  ),
  planning(
    label: 'Planning',
    code: 'PLAN',
    color: Color(0xFF60A5FA), // Blue
    description: 'Architecture, scoping, and roadmap definition',
  ),
  active(
    label: 'Active',
    code: 'ACTIVE',
    color: Color(0xFF10B981), // Emerald
    description: 'Currently receiving active focus and momentum',
  ),
  inDevelopment(
    label: 'In Development',
    code: 'DEV',
    color: Color(0xFF38BDF8), // Cyan
    description: 'Under active construction, secondary to primary focus',
  ),
  paused(
    label: 'Paused',
    code: 'PAUSED',
    color: Color(0xFFF59E0B), // Amber
    description: 'Deliberately paused or deferred for future cycle',
  ),
  maintenance(
    label: 'Maintenance',
    code: 'MAINT',
    color: Color(0xFFA78BFA), // Purple-Slate
    description: 'Operational, receiving fixes and minor enhancements',
  ),
  complete(
    label: 'Complete',
    code: 'DONE',
    color: Color(0xFF34D399), // Mint Green
    description: 'Shipped, achieved core milestones',
  ),
  archived(
    label: 'Archived',
    code: 'ARCHIVE',
    color: Color(0xFF64748B), // Muted Slate
    description: 'Historical archive, no further development planned',
  );

  final String label;
  final String code;
  final Color color;
  final String description;

  const ProjectHumanStatus({
    required this.label,
    required this.code,
    required this.color,
    required this.description,
  });

  static ProjectHumanStatus? fromString(String? val) {
    if (val == null || val.isEmpty) return null;
    for (final status in ProjectHumanStatus.values) {
      if (status.name.toLowerCase() == val.toLowerCase() ||
          status.code.toLowerCase() == val.toLowerCase() ||
          status.label.toLowerCase() == val.toLowerCase()) {
        return status;
      }
    }
    return null;
  }
}

/// Observed development activity derived strictly from external signals
/// (e.g. GitHub commits, local git repository activity).
enum ObservedActivity {
  veryActive(
    label: 'Very Active',
    code: 'SIGNAL_HIGH',
    color: Color(0xFF10B981), // Emerald
    detail: 'Commits within the last 72 hours',
  ),
  active(
    label: 'Active',
    code: 'SIGNAL_ACTIVE',
    color: Color(0xFF34D399), // Light Emerald
    detail: 'Commits within the last 7 days',
  ),
  quiet(
    label: 'Quiet',
    code: 'SIGNAL_QUIET',
    color: Color(0xFFFBBF24), // Amber
    detail: 'Commits within the last 30 days',
  ),
  stale(
    label: 'Stale',
    code: 'SIGNAL_STALE',
    color: Color(0xFFF87171), // Coral
    detail: 'No commits for over 30 days',
  ),
  noActivity(
    label: 'No Activity',
    code: 'SIGNAL_NONE',
    color: Color(0xFF94A3B8), // Slate
    detail: 'No commits recorded in tracked branch',
  ),
  notConnected(
    label: 'GitHub Not Connected',
    code: 'UNTRACKED',
    color: Color(0xFF64748B), // Muted
    detail: 'No remote repository linked',
  );

  final String label;
  final String code;
  final Color color;
  final String detail;

  const ObservedActivity({
    required this.label,
    required this.code,
    required this.color,
    required this.detail,
  });

  static ObservedActivity fromString(String? val) {
    if (val == null || val.isEmpty) return ObservedActivity.notConnected;
    for (final a in ObservedActivity.values) {
      if (a.name.toLowerCase() == val.toLowerCase() ||
          a.code.toLowerCase() == val.toLowerCase() ||
          a.label.toLowerCase() == val.toLowerCase()) {
        return a;
      }
    }
    return ObservedActivity.notConnected;
  }
}

/// Project priority level.
enum ProjectPriority {
  p0(label: 'P0 - Critical', short: 'P0', color: Color(0xFFEF4444)),
  p1(label: 'P1 - High', short: 'P1', color: Color(0xFFF59E0B)),
  p2(label: 'P2 - Normal', short: 'P2', color: Color(0xFF38BDF8)),
  p3(label: 'P3 - Low', short: 'P3', color: Color(0xFF94A3B8)),
  none(label: 'No Priority', short: '--', color: Color(0xFF64748B));

  final String label;
  final String short;
  final Color color;

  const ProjectPriority({
    required this.label,
    required this.short,
    required this.color,
  });

  static ProjectPriority fromString(String? val) {
    if (val == null || val.isEmpty) return ProjectPriority.none;
    for (final p in ProjectPriority.values) {
      if (p.name.toLowerCase() == val.toLowerCase() ||
          p.short.toLowerCase() == val.toLowerCase()) {
        return p;
      }
    }
    return ProjectPriority.none;
  }
}

/// Project ecosystem type.
enum ProjectType {
  flutterApp(label: 'Flutter App', icon: Icons.phone_android_rounded),
  desktopApp(label: 'Desktop App', icon: Icons.desktop_windows_rounded),
  systemTool(label: 'System Tool', icon: Icons.terminal_rounded),
  cliPackage(label: 'CLI / Package', icon: Icons.code_rounded),
  webApp(label: 'Web Application', icon: Icons.language_rounded),
  hardware(label: 'Hardware / Robotics', icon: Icons.memory_rounded),
  service(label: 'Service / Daemon', icon: Icons.dns_rounded),
  other(label: 'Project', icon: Icons.folder_rounded);

  final String label;
  final IconData icon;

  const ProjectType({required this.label, required this.icon});

  static ProjectType fromString(String? val) {
    if (val == null || val.isEmpty) return ProjectType.other;
    for (final t in ProjectType.values) {
      if (t.name.toLowerCase() == val.toLowerCase() ||
          t.label.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return ProjectType.other;
  }
}
