import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/data/models/habit_entry.dart';
import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  String name;
  String? description;
  HabitType type;
  HabitCategory category;
  IconData? icon;
  Color? color;
  HabitFrequency frequency;
  List<int> customDays;
  double? targetValue;
  String? targetUnit;
  int? reminderHour;
  int? reminderMinute;
  bool hasReminder;
  HabitPriority priority;
  int durationMinutes;
  bool isArchived;
  bool isPaused;
  List<HabitEntry> entries;
  DateTime createdAt;
  DateTime? completedAt;

  Habit({
    String? id,
    required this.name,
    this.description,
    this.type = HabitType.Positive,
    this.category = HabitCategory.Health,
    this.icon,
    this.color,
    this.frequency = HabitFrequency.Daily,
    this.customDays = const [],
    this.targetValue,
    this.targetUnit,
    this.reminderHour,
    this.reminderMinute,
    this.hasReminder = false,
    this.priority = HabitPriority.Medium,
    this.durationMinutes = 0,
    this.isArchived = false,
    this.isPaused = false,
    List<HabitEntry>? entries,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        entries = entries ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.index,
        'category': category.index,
        'icon': icon?.codePoint,
        'color': color?.value,
        'frequency': frequency.index,
        'customDays': customDays,
        'targetValue': targetValue,
        'targetUnit': targetUnit,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'hasReminder': hasReminder,
        'priority': priority.index,
        'durationMinutes': durationMinutes,
        'isArchived': isArchived,
        'isPaused': isPaused,
        'entries': entries.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  static Habit fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        type: HabitType.values[json['type'] ?? 0],
        category: HabitCategory.values[json['category'] ?? 0],
        icon: json['icon'] != null
            ? IconData(json['icon'], fontFamily: 'MaterialIcons')
            : null,
        color: json['color'] != null ? Color(json['color']) : null,
        frequency: HabitFrequency.values[json['frequency'] ?? 0],
        customDays: List<int>.from(json['customDays'] ?? []),
        targetValue: json['targetValue']?.toDouble(),
        targetUnit: json['targetUnit'],
        reminderHour: json['reminderHour'],
        reminderMinute: json['reminderMinute'],
        hasReminder: json['hasReminder'] ?? false,
        priority: HabitPriority.values[json['priority'] ?? 1],
        durationMinutes: json['durationMinutes'] ?? 0,
        isArchived: json['isArchived'] ?? false,
        isPaused: json['isPaused'] ?? false,
        entries: (json['entries'] as List?)
                ?.map((e) => HabitEntry.fromJson(e))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
      );

  bool isDueToday() {
    if (isPaused) return false;

    final now = DateTime.now();

    switch (frequency) {
      case HabitFrequency.Daily:
        return true;
      case HabitFrequency.MondayOnly:
        return now.weekday == DateTime.monday;
      case HabitFrequency.Weekend:
        return now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;
      case HabitFrequency.Every2Days:
        final daysSinceCreated = now.difference(createdAt).inDays;
        return daysSinceCreated % 2 == 0;
      case HabitFrequency.Weekly:
        return now.weekday == createdAt.weekday;
      case HabitFrequency.Monthly:
        return now.day == createdAt.day;
      case HabitFrequency.CustomDays:
        final todayIndex = now.weekday % 7;
        return customDays.contains(todayIndex);
    }
  }

  bool isCompletedToday() {
    final today = DateTime.now();
    return entries.any((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);
  }

  double get todayProgress {
    if (!isDueToday()) return 1.0;
    if (isCompletedToday()) return 1.0;
    return 0.0;
  }

  int get currentStreak {
    if (entries.isEmpty) return 0;

    int streak = 0;
    var sortedEntries = [...entries]..sort((a, b) => b.date.compareTo(a.date));

    for (var entry in sortedEntries) {
      if (entry.count > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int get bestStreak {
    if (entries.isEmpty) return 0;

    int best = 0;
    int current = 0;

    var sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    for (var entry in sortedEntries) {
      if (entry.count > 0) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }

    return best;
  }

  int get totalCompletions => entries.where((e) => e.count > 0).length;

  String get frequencyDisplayName => frequency.displayName;

  String get categoryDisplayName => category.displayName;

  String get typeDisplayName => type.displayName;

  String get priorityDisplayName => priority.displayName;

  String get formattedName => name;

  bool get hasEntries => entries.isNotEmpty;

  String? get reminderTimeText {
    if (!hasReminder || reminderHour == null || reminderMinute == null) {
      return null;
    }
    final hour = reminderHour!.toString().padLeft(2, '0');
    final minute = reminderMinute!.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int getNextDayNumber() {
    return entries.length + 1;
  }

  bool isStreakMilestone() {
    const milestones = [7, 14, 21, 30, 50, 100, 365];
    return milestones.contains(currentStreak);
  }

  String getMilestoneMessage() {
    switch (currentStreak) {
      case 7:
        return 'Amazing! 7 days in a row! You\'re building a strong habit!';
      case 14:
        return 'Incredible! 2 weeks straight! You\'re unstoppable!';
      case 21:
        return 'Fantastic! 21 days! They say it takes 21 days to form a habit!';
      case 30:
        return 'Wow! 30 days! You\'ve officially made this a part of your life!';
      case 50:
        return 'Outstanding! 50 days! You\'re a true champion!';
      case 100:
        return 'Legendary! 100 days! You\'ve achieved something extraordinary!';
      case 365:
        return 'Unbelievable! A full year! You\'re an inspiration to everyone!';
      default:
        return 'Great job! Keep up the amazing work!';
    }
  }

  String getRandomMotivationalMessage() {
    final messages = [
      'You\'re doing great! Keep it up!',
      'Every day you\'re getting stronger!',
      'Consistency is the key to success!',
      'You\'re building something amazing!',
      'Small steps lead to big changes!',
      'Your dedication is inspiring!',
      'Keep pushing forward!',
      'You\'re making a real difference!',
      'Stay focused, stay determined!',
      'Your future self will thank you!',
    ];
    return messages[Random().nextInt(messages.length)];
  }
}
