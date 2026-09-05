import 'package:flutter/material.dart';

enum NoteCategory {
  note(label: 'Note', icon: Icons.notes_rounded, color: Color(0xFF94A3B8)),
  decision(label: 'Decision', icon: Icons.gavel_rounded, color: Color(0xFFF59E0B)),
  architecture(label: 'Architecture', icon: Icons.architecture_rounded, color: Color(0xFF38BDF8)),
  idea(label: 'Idea', icon: Icons.lightbulb_outline_rounded, color: Color(0xFF34D399));

  final String label;
  final IconData icon;
  final Color color;

  const NoteCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  static NoteCategory fromString(String? val) {
    if (val == null) return NoteCategory.note;
    for (final c in NoteCategory.values) {
      if (c.name.toLowerCase() == val.toLowerCase() ||
          c.label.toLowerCase() == val.toLowerCase()) {
        return c;
      }
    }
    return NoteCategory.note;
  }
}

class ProjectNote {
  final String id;
  final String title;
  final String content;
  final NoteCategory category;
  final DateTime createdAt;

  const ProjectNote({
    required this.id,
    required this.title,
    required this.content,
    this.category = NoteCategory.note,
    required this.createdAt,
  });

  ProjectNote copyWith({
    String? id,
    String? title,
    String? content,
    NoteCategory? category,
    DateTime? createdAt,
  }) {
    return ProjectNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProjectNote.fromJson(Map<String, dynamic> json) => ProjectNote(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        category: NoteCategory.fromString(json['category'] as String?),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
