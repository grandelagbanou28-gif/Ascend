import 'package:uuid/uuid.dart';
import 'package:ascend/data/models/sub_goal.dart';

enum GoalStatus { active, completed, paused, abandoned }

extension GoalStatusExtension on GoalStatus {
  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.completed:
        return 'Terminé';
      case GoalStatus.paused:
        return 'En pause';
      case GoalStatus.abandoned:
        return 'Abandonné';
    }
  }
}

class Goal {
  final String id;
  String name;
  String? description;
  String? duration; // e.g., "6 mois", "1 an", "3 semaines"
  DateTime startDate;
  DateTime? endDate;
  GoalStatus status;
  List<SubGoal> subGoals;
  DateTime createdAt;
  DateTime? completedAt;

  Goal({
    String? id,
    required this.name,
    this.description,
    this.duration,
    DateTime? startDate,
    this.endDate,
    this.status = GoalStatus.active,
    List<SubGoal>? subGoals,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now(),
        subGoals = subGoals ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get progression {
    if (subGoals.isEmpty) return 0.0;
    final total = subGoals.fold<double>(0.0, (sum, sg) => sum + sg.progression);
    return total / subGoals.length;
  }

  int get completedSubGoals => subGoals.where((sg) => sg.isCompleted).length;

  int get totalSubGoals => subGoals.length;

  bool get isCompleted => status == GoalStatus.completed;

  String get statusDisplayName => status.displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'duration': duration,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status.index,
        'subGoals': subGoals.map((sg) => sg.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  static Goal fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        duration: json['duration'],
        startDate: DateTime.parse(json['startDate']),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        status: GoalStatus.values[json['status'] ?? 0],
        subGoals: (json['subGoals'] as List?)
                ?.map((sg) => SubGoal.fromJson(sg))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
      );
}
