enum MilestoneStatus {
  pending(label: 'Pending'),
  inProgress(label: 'In Progress'),
  completed(label: 'Completed');

  final String label;
  const MilestoneStatus({required this.label});

  static MilestoneStatus fromString(String? val) {
    if (val == null) return MilestoneStatus.pending;
    for (final s in MilestoneStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase()) return s;
    }
    return MilestoneStatus.pending;
  }
}

class ProjectMilestone {
  final String id;
  final String title;
  final String? description;
  final MilestoneStatus status;
  final bool isCurrent;
  final DateTime? targetDate;
  final DateTime? completedDate;

  const ProjectMilestone({
    required this.id,
    required this.title,
    this.description,
    this.status = MilestoneStatus.pending,
    this.isCurrent = false,
    this.targetDate,
    this.completedDate,
  });

  ProjectMilestone copyWith({
    String? id,
    String? title,
    String? description,
    MilestoneStatus? status,
    bool? isCurrent,
    DateTime? targetDate,
    DateTime? completedDate,
  }) {
    return ProjectMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'isCurrent': isCurrent,
        'targetDate': targetDate?.toIso8601String(),
        'completedDate': completedDate?.toIso8601String(),
      };

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) =>
      ProjectMilestone(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        status: MilestoneStatus.fromString(json['status'] as String?),
        isCurrent: json['isCurrent'] as bool? ?? false,
        targetDate: json['targetDate'] != null
            ? DateTime.tryParse(json['targetDate'] as String)
            : null,
        completedDate: json['completedDate'] != null
            ? DateTime.tryParse(json['completedDate'] as String)
            : null,
      );
}
