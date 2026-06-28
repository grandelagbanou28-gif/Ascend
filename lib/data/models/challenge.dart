import 'package:uuid/uuid.dart';

enum ChallengeDifficulty { easy, medium, hard, extreme }

extension ChallengeDifficultyExtension on ChallengeDifficulty {
  String get displayName {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'Facile';
      case ChallengeDifficulty.medium:
        return 'Moyen';
      case ChallengeDifficulty.hard:
        return 'Difficile';
      case ChallengeDifficulty.extreme:
        return 'Extrême';
    }
  }

  int get xpMultiplier {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 1;
      case ChallengeDifficulty.medium:
        return 2;
      case ChallengeDifficulty.hard:
        return 3;
      case ChallengeDifficulty.extreme:
        return 5;
    }
  }
}

enum ChallengeStatus { available, active, completed, failed }

extension ChallengeStatusExtension on ChallengeStatus {
  String get displayName {
    switch (this) {
      case ChallengeStatus.available:
        return 'Disponible';
      case ChallengeStatus.active:
        return 'En cours';
      case ChallengeStatus.completed:
        return 'Terminé';
      case ChallengeStatus.failed:
        return 'Échoué';
    }
  }
}

class Challenge {
  final String id;
  String name;
  String description;
  int durationDays;
  ChallengeDifficulty difficulty;
  int xpReward;
  String? badgeName;
  String? rewardDescription;
  ChallengeStatus status;
  DateTime? startDate;
  DateTime? completedAt;
  int daysCompleted;
  List<String> completedDays; // ISO date strings
  DateTime createdAt;

  Challenge({
    String? id,
    required this.name,
    required this.description,
    required this.durationDays,
    this.difficulty = ChallengeDifficulty.medium,
    this.xpReward = 100,
    this.badgeName,
    this.rewardDescription,
    this.status = ChallengeStatus.available,
    this.startDate,
    this.completedAt,
    this.daysCompleted = 0,
    List<String>? completedDays,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        completedDays = completedDays ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get progression {
    if (durationDays == 0) return 0.0;
    return (daysCompleted / durationDays).clamp(0.0, 1.0);
  }

  int get remainingDays {
    if (startDate == null) return durationDays;
    final elapsed = DateTime.now().difference(startDate!).inDays;
    return (durationDays - elapsed).clamp(0, durationDays);
  }

  bool get isActive => status == ChallengeStatus.active;

  bool get isCompleted => status == ChallengeStatus.completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'durationDays': durationDays,
        'difficulty': difficulty.index,
        'xpReward': xpReward,
        'badgeName': badgeName,
        'rewardDescription': rewardDescription,
        'status': status.index,
        'startDate': startDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'daysCompleted': daysCompleted,
        'completedDays': completedDays,
        'createdAt': createdAt.toIso8601String(),
      };

  static Challenge fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        durationDays: json['durationDays'],
        difficulty: ChallengeDifficulty.values[json['difficulty'] ?? 1],
        xpReward: json['xpReward'] ?? 100,
        badgeName: json['badgeName'],
        rewardDescription: json['rewardDescription'],
        status: ChallengeStatus.values[json['status'] ?? 0],
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        daysCompleted: json['daysCompleted'] ?? 0,
        completedDays: List<String>.from(json['completedDays'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );

  static List<Challenge> presets = [
    Challenge(
      name: 'Pas de sucre',
      description: 'Éviter le sucre ajouté pendant la durée du défi',
      durationDays: 30,
      difficulty: ChallengeDifficulty.hard,
      xpReward: 300,
      badgeName: 'Sugar Free',
      rewardDescription: 'Badge "Sugar Free" + 300 XP',
    ),
    Challenge(
      name: 'Lecture quotidienne',
      description: 'Lire au moins 20 minutes chaque jour',
      durationDays: 21,
      difficulty: ChallengeDifficulty.easy,
      xpReward: 150,
      badgeName: 'Bookworm',
      rewardDescription: 'Badge "Bookworm" + 150 XP',
    ),
    Challenge(
      name: '10000 pas',
      description: 'Marcher 10000 pas par jour',
      durationDays: 30,
      difficulty: ChallengeDifficulty.medium,
      xpReward: 250,
      badgeName: 'Step Master',
      rewardDescription: 'Badge "Step Master" + 250 XP',
    ),
    Challenge(
      name: 'Réveil à 5h',
      description: 'Se réveiller à 5h du matin chaque jour',
      durationDays: 14,
      difficulty: ChallengeDifficulty.hard,
      xpReward: 200,
      badgeName: 'Early Bird',
      rewardDescription: 'Badge "Early Bird" + 200 XP',
    ),
    Challenge(
      name: 'No Social Media',
      description: 'Pas de réseaux sociaux pendant la durée du défi',
      durationDays: 7,
      difficulty: ChallengeDifficulty.medium,
      xpReward: 100,
      badgeName: 'Digital Detox',
      rewardDescription: 'Badge "Digital Detox" + 100 XP',
    ),
    Challenge(
      name: 'Programmation quotidienne',
      description: 'Coder au moins 1 heure chaque jour',
      durationDays: 60,
      difficulty: ChallengeDifficulty.hard,
      xpReward: 500,
      badgeName: 'Code Warrior',
      rewardDescription: 'Badge "Code Warrior" + 500 XP',
    ),
  ];

  static List<int> presetDurations = [7, 14, 21, 30, 60, 90, 365];
}
