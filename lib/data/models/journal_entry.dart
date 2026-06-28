import 'package:uuid/uuid.dart';

enum Mood { happy, neutral, sad }

extension MoodExtension on Mood {
  String get emoji {
    switch (this) {
      case Mood.happy:
        return '😀';
      case Mood.neutral:
        return '😐';
      case Mood.sad:
        return '😞';
    }
  }

  String get displayName {
    switch (this) {
      case Mood.happy:
        return 'Heureux';
      case Mood.neutral:
        return 'Neutre';
      case Mood.sad:
        return 'Triste';
    }
  }
}

class JournalEntry {
  final String id;
  DateTime date;
  Mood mood;
  String? textContent;
  List<String> photoPaths;
  List<String> audioPaths;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;

  JournalEntry({
    String? id,
    required this.date,
    this.mood = Mood.neutral,
    this.textContent,
    List<String>? photoPaths,
    List<String>? audioPaths,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        photoPaths = photoPaths ?? [],
        audioPaths = audioPaths ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get hasContent =>
      (textContent != null && textContent!.isNotEmpty) ||
      photoPaths.isNotEmpty ||
      audioPaths.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mood': mood.index,
        'textContent': textContent,
        'photoPaths': photoPaths,
        'audioPaths': audioPaths,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static JournalEntry fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        mood: Mood.values[json['mood'] ?? 1],
        textContent: json['textContent'],
        photoPaths: List<String>.from(json['photoPaths'] ?? []),
        audioPaths: List<String>.from(json['audioPaths'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );
}
