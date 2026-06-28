import 'package:uuid/uuid.dart';

enum GoalPriority { low, medium, high, urgent }

extension GoalPriorityExtension on GoalPriority {
  String get displayName {
    switch (this) {
      case GoalPriority.low:
        return 'Basse';
      case GoalPriority.medium:
        return 'Moyenne';
      case GoalPriority.high:
        return 'Haute';
      case GoalPriority.urgent:
        return 'Urgente';
    }
  }
}

class SubGoal {
  final String id;
  String name;
  DateTime? dueDate;
  GoalPriority priority;
  double progression; // 0.0 to 1.0
  bool isCompleted;
  DateTime? completedAt;
  String? notes;
  DateTime createdAt;

  SubGoal({
    String? id,
    required this.name,
    this.dueDate,
    this.priority = GoalPriority.medium,
    this.progression = 0.0,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.index,
        'progression': progression,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  static SubGoal fromJson(Map<String, dynamic> json) => SubGoal(
        id: json['id'],
        name: json['name'],
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        priority: GoalPriority.values[json['priority'] ?? 1],
        progression: (json['progression'] ?? 0).toDouble(),
        isCompleted: json['isCompleted'] ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        notes: json['notes'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
