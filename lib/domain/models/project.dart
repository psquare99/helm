import 'project_status.dart';
import 'github_telemetry.dart';
import 'project_task.dart';
import 'project_milestone.dart';
import 'project_note.dart';
import 'project_link.dart';

/// The fundamental entity of the P² Project Manager system.
/// Owns project information, human-declared state, and observed telemetry.
class Project {
  final String id;
  final String name;
  final String? description;
  final ProjectType type;
  final String? localPath;
  final ProjectHumanStatus? humanStatus;
  final ProjectPriority priority;
  final String? currentMilestone;
  final String? nextAction;
  final GitHubTelemetry? github;
  final List<ProjectTask> tasks;
  final List<ProjectMilestone> milestones;
  final List<ProjectNote> notes;
  final List<ProjectLink> links;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.type = ProjectType.other,
    this.localPath,
    this.humanStatus,
    this.priority = ProjectPriority.none,
    this.currentMilestone,
    this.nextAction,
    this.github,
    this.tasks = const [],
    this.milestones = const [],
    this.notes = const [],
    this.links = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Observed activity strictly from GitHub or external signals.
  /// Does NOT override human status.
  ObservedActivity get effectiveObservedActivity {
    if (github == null) {
      return ObservedActivity.notConnected;
    }
    return github!.observedActivity;
  }

  /// Authoritative human status display string
  String get statusDisplay => humanStatus?.label ?? 'Status not set';

  /// Current milestone display string (or empty state)
  String get milestoneDisplay {
    if (currentMilestone != null && currentMilestone!.trim().isNotEmpty) {
      return currentMilestone!.trim();
    }
    final active = milestones.where((m) => m.isCurrent).firstOrNull;
    if (active != null && active.title.trim().isNotEmpty) {
      return active.title.trim();
    }
    return 'No milestones yet';
  }

  bool get hasMilestone =>
      (currentMilestone != null && currentMilestone!.trim().isNotEmpty) ||
      milestones.any((m) => m.isCurrent);

  /// Next action display string (or empty state)
  String get nextActionDisplay {
    if (nextAction != null && nextAction!.trim().isNotEmpty) {
      return nextAction!.trim();
    }
    final firstIncomplete = tasks.where((t) => !t.isCompleted).firstOrNull;
    if (firstIncomplete != null) {
      return firstIncomplete.title;
    }
    return 'No next action defined';
  }

  bool get hasNextAction =>
      (nextAction != null && nextAction!.trim().isNotEmpty) ||
      tasks.any((t) => !t.isCompleted);

  bool get hasGithub => github != null;

  int get pendingTasksCount => tasks.where((t) => !t.isCompleted).length;
  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;

  /// High momentum check: Active human status and recent commits
  bool get hasHighMomentum {
    return humanStatus == ProjectHumanStatus.active &&
        (effectiveObservedActivity == ObservedActivity.veryActive ||
            effectiveObservedActivity == ObservedActivity.active);
  }

  /// Needs attention check: Active with no next action or stale activity
  bool get needsAttention {
    if (humanStatus == ProjectHumanStatus.active) {
      if (!hasNextAction) return true;
      if (effectiveObservedActivity == ObservedActivity.stale) return true;
    }
    return false;
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    ProjectType? type,
    String? localPath,
    ProjectHumanStatus? humanStatus,
    bool clearHumanStatus = false,
    ProjectPriority? priority,
    String? currentMilestone,
    bool clearMilestone = false,
    String? nextAction,
    bool clearNextAction = false,
    GitHubTelemetry? github,
    bool clearGithub = false,
    List<ProjectTask>? tasks,
    List<ProjectMilestone>? milestones,
    List<ProjectNote>? notes,
    List<ProjectLink>? links,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      humanStatus: clearHumanStatus ? null : (humanStatus ?? this.humanStatus),
      priority: priority ?? this.priority,
      currentMilestone:
          clearMilestone ? null : (currentMilestone ?? this.currentMilestone),
      nextAction: clearNextAction ? null : (nextAction ?? this.nextAction),
      github: clearGithub ? null : (github ?? this.github),
      tasks: tasks ?? this.tasks,
      milestones: milestones ?? this.milestones,
      notes: notes ?? this.notes,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'localPath': localPath,
        'humanStatus': humanStatus?.name,
        'priority': priority.name,
        'currentMilestone': currentMilestone,
        'nextAction': nextAction,
        'github': github?.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled Project',
        description: json['description'] as String?,
        type: ProjectType.fromString(json['type'] as String?),
        localPath: json['localPath'] as String?,
        humanStatus: ProjectHumanStatus.fromString(json['humanStatus'] as String?),
        priority: ProjectPriority.fromString(json['priority'] as String?),
        currentMilestone: json['currentMilestone'] as String?,
        nextAction: json['nextAction'] as String?,
        github: json['github'] != null
            ? GitHubTelemetry.fromJson(json['github'] as Map<String, dynamic>)
            : null,
        tasks: (json['tasks'] as List<dynamic>?)
                ?.map((t) => ProjectTask.fromJson(t as Map<String, dynamic>))
                .toList() ??
            const [],
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((m) => ProjectMilestone.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: (json['notes'] as List<dynamic>?)
                ?.map((n) => ProjectNote.fromJson(n as Map<String, dynamic>))
                .toList() ??
            const [],
        links: (json['links'] as List<dynamic>?)
                ?.map((l) => ProjectLink.fromJson(l as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
