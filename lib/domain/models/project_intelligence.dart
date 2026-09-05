import 'package:flutter/material.dart';

enum ObservationType {
  momentum(label: 'Momentum', icon: Icons.trending_up_rounded, color: Color(0xFF10B981)),
  attention(label: 'Attention Required', icon: Icons.error_outline_rounded, color: Color(0xFFF59E0B)),
  milestoneProgress(label: 'Milestone', icon: Icons.flag_outlined, color: Color(0xFF38BDF8)),
  untracked(label: 'Telemetry Gap', icon: Icons.link_off_rounded, color: Color(0xFF94A3B8)),
  recommendation(label: 'Focus Recommendation', icon: Icons.bolt_rounded, color: Color(0xFFA78BFA));

  final String label;
  final IconData icon;
  final Color color;

  const ObservationType({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Extensible intelligence observation produced by reasoning over
/// human project state, GitHub activity, tasks, and milestones.
class ProjectObservation {
  final String id;
  final String? projectId;
  final String? projectName;
  final ObservationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? actionableHint;

  const ProjectObservation({
    required this.id,
    this.projectId,
    this.projectName,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.actionableHint,
  });
}
