// lib/app_enums.dart

import 'package:flutter/material.dart';

// Habit types
enum HabitType { 
  Positive,    // Positive habit (e.g., exercise)
  Negative,    // Negative habit to avoid (e.g., smoking)
  Measurable,  // Measurable goal (e.g., drink 3L water)
  Timed,       // Timed activity (e.g., read 45 minutes)
  Counting     // Count-based (e.g., 100 push-ups)
}

// Frequencies
enum HabitFrequency { 
  Daily,           // Tous les jours
  MondayOnly,      // Lundi uniquement
  Weekend,         // Week-end
  Every2Days,      // Tous les 2 jours
  Weekly,          // Toutes les semaines
  Monthly,         // Tous les mois
  CustomDays       // Personnalisée
}

// Categories
enum HabitCategory {
  Health,              // Santé
  Sport,               // Sport
  Reading,             // Lecture
  Work,                // Travail
  Studies,             // Études
  Finance,             // Finance
  Religion,            // Religion
  Meditation,          // Méditation
  Sleep,               // Sommeil
  Nutrition,           // Nutrition
  Creativity,          // Créativité
  PersonalDevelopment, // Développement personnel
  Languages,           // Langues
  Music,               // Musique
  Programming,         // Programmation
  Custom               // Personnalisée
}

// Units
enum HabitUnit {
  Count,
  Minutes,
  Hours,
  Pages,
  Kilometers,
  Miles,
  Grams,
  Pounds,
  Dollars,
  Liters,
  Custom
}

// Priority
enum HabitPriority {
  Low,
  Medium,
  High,
  Urgent
}

// Icons for habits
class HabitIcons {
  static const Map<String, IconData> icons = {
    'fitness': Icons.fitness_center,
    'run': Icons.directions_run,
    'bedtime': Icons.bedtime,
    'book': Icons.book,
    'work': Icons.work,
    'school': Icons.school,
    'savings': Icons.savings,
    'church': Icons.church,
    'self_improvement': Icons.self_improvement,
    'restaurant': Icons.restaurant,
    'palette': Icons.palette,
    'trending_up': Icons.trending_up,
    'translate': Icons.translate,
    'music_note': Icons.music_note,
    'code': Icons.code,
    'water_drop': Icons.water_drop,
    'local_fire_department': Icons.local_fire_department,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'eco': Icons.eco,
    'spa': Icons.spa,
    'psychology': Icons.psychology,
    'timer': Icons.timer,
    'flag': Icons.flag,
    'emoji_events': Icons.emoji_events,
    'bolt': Icons.bolt,
    'wb_sunny': Icons.wb_sunny,
    'nights_stay': Icons.nights_stay,
    'monitor_heart': Icons.monitor_heart,
    'medical_services': Icons.medical_services,
    'nutrition': Icons.local_grocery_store,
    'sleep': Icons.bedtime_outlined,
    'study': Icons.menu_book,
    'meditation': Icons.self_improvement,
    'creativity': Icons.brush,
    'productivity': Icons.rocket_launch,
  };

  static IconData? getIcon(String name) => icons[name];
  static List<String> get iconNames => icons.keys.toList();
}

// Colors for habits
class HabitColors {
  static const List<Color> colors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
  ];

  static const List<String> colorNames = [
    'Bleu',
    'Vert',
    'Orange',
    'Rouge',
    'Violet',
    'Cyan',
    'Orange foncé',
    'Marron',
    'Bleu Gris',
    'Rose',
  ];
}

// Add a utility function to format PascalCase or camelCase to spaced text
String formatPascalCase(String text) {
  if (text.isEmpty) return text;
  
  // Handle case where the text is already formatted with spaces
  if (text.contains(' ')) return text;
  
  // Add a space before each capital letter, but not the first one
  final formattedText = text.replaceAllMapped(
    RegExp(r'(?<=[a-z])[A-Z]'),
    (match) => ' ${match.group(0)}',
  );
  
  // Capitalize the first letter
  if (formattedText.isNotEmpty) {
    return formattedText[0].toUpperCase() + formattedText.substring(1);
  }
  
  return formattedText;
} 

// Extension for HabitCategory
extension HabitCategoryExtension on HabitCategory {
  String get displayName {
    switch (this) {
      case HabitCategory.Health:
        return 'Santé';
      case HabitCategory.Sport:
        return 'Sport';
      case HabitCategory.Reading:
        return 'Lecture';
      case HabitCategory.Work:
        return 'Travail';
      case HabitCategory.Studies:
        return 'Études';
      case HabitCategory.Finance:
        return 'Finance';
      case HabitCategory.Religion:
        return 'Religion';
      case HabitCategory.Meditation:
        return 'Méditation';
      case HabitCategory.Sleep:
        return 'Sommeil';
      case HabitCategory.Nutrition:
        return 'Nutrition';
      case HabitCategory.Creativity:
        return 'Créativité';
      case HabitCategory.PersonalDevelopment:
        return 'Développement personnel';
      case HabitCategory.Languages:
        return 'Langues';
      case HabitCategory.Music:
        return 'Musique';
      case HabitCategory.Programming:
        return 'Programmation';
      case HabitCategory.Custom:
        return 'Personnalisée';
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCategory.Health:
        return Icons.favorite;
      case HabitCategory.Sport:
        return Icons.fitness_center;
      case HabitCategory.Reading:
        return Icons.book;
      case HabitCategory.Work:
        return Icons.work;
      case HabitCategory.Studies:
        return Icons.school;
      case HabitCategory.Finance:
        return Icons.savings;
      case HabitCategory.Religion:
        return Icons.church;
      case HabitCategory.Meditation:
        return Icons.self_improvement;
      case HabitCategory.Sleep:
        return Icons.bedtime;
      case HabitCategory.Nutrition:
        return Icons.restaurant;
      case HabitCategory.Creativity:
        return Icons.palette;
      case HabitCategory.PersonalDevelopment:
        return Icons.trending_up;
      case HabitCategory.Languages:
        return Icons.translate;
      case HabitCategory.Music:
        return Icons.music_note;
      case HabitCategory.Programming:
        return Icons.code;
      case HabitCategory.Custom:
        return Icons.category;
    }
  }
}

// Extension for HabitFrequency
extension HabitFrequencyExtension on HabitFrequency {
  String get displayName {
    switch (this) {
      case HabitFrequency.Daily:
        return 'Tous les jours';
      case HabitFrequency.MondayOnly:
        return 'Lundi uniquement';
      case HabitFrequency.Weekend:
        return 'Week-end';
      case HabitFrequency.Every2Days:
        return 'Tous les 2 jours';
      case HabitFrequency.Weekly:
        return 'Toutes les semaines';
      case HabitFrequency.Monthly:
        return 'Tous les mois';
      case HabitFrequency.CustomDays:
        return 'Personnalisée';
    }
  }
}

// Extension for HabitType
extension HabitTypeExtension on HabitType {
  String get displayName {
    switch (this) {
      case HabitType.Positive:
        return 'Positive';
      case HabitType.Negative:
        return 'Négative';
      case HabitType.Measurable:
        return 'Mesurable';
      case HabitType.Timed:
        return 'Chronométrée';
      case HabitType.Counting:
        return 'Comptage';
    }
  }

  String get description {
    switch (this) {
      case HabitType.Positive:
        return 'Ex: Faire du sport';
      case HabitType.Negative:
        return 'Ex: Ne pas fumer';
      case HabitType.Measurable:
        return 'Ex: Boire 3 litres d\'eau';
      case HabitType.Timed:
        return 'Ex: Lire 45 minutes';
      case HabitType.Counting:
        return 'Ex: Faire 100 pompes';
    }
  }

  IconData get icon {
    switch (this) {
      case HabitType.Positive:
        return Icons.thumb_up;
      case HabitType.Negative:
        return Icons.thumb_down;
      case HabitType.Measurable:
        return Icons.straighten;
      case HabitType.Timed:
        return Icons.timer;
      case HabitType.Counting:
        return Icons.onetwothree;
    }
  }
}

// Extension for HabitPriority
extension HabitPriorityExtension on HabitPriority {
  String get displayName {
    switch (this) {
      case HabitPriority.Low:
        return 'Basse';
      case HabitPriority.Medium:
        return 'Moyenne';
      case HabitPriority.High:
        return 'Haute';
      case HabitPriority.Urgent:
        return 'Urgente';
    }
  }

  Color get color {
    switch (this) {
      case HabitPriority.Low:
        return Colors.green;
      case HabitPriority.Medium:
        return Colors.orange;
      case HabitPriority.High:
        return Colors.red;
      case HabitPriority.Urgent:
        return Colors.purple;
    }
  }
}
