class UserProfile {
  final String id;
  final String? email;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? country;
  final String? language;
  final String? timezone;
  final DateTime createdAt;
  final int level;
  final int xp;
  final int currentStreak;
  final int bestStreak;
  final int totalHabits;
  final int challengesCompleted;
  final int totalFocusTime;
  final String? favoriteQuote;
  final String? primaryColor;
  final String? theme;
  final String? profileIcon;

  UserProfile({
    required this.id,
    this.email,
    this.displayName = '',
    this.username,
    this.avatarUrl,
    this.bannerUrl,
    this.country,
    this.language,
    this.timezone,
    DateTime? createdAt,
    this.level = 1,
    this.xp = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalHabits = 0,
    this.challengesCompleted = 0,
    this.totalFocusTime = 0,
    this.favoriteQuote,
    this.primaryColor,
    this.theme,
    this.profileIcon,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'],
      displayName: json['display_name'] ?? '',
      username: json['username'],
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      country: json['country'],
      language: json['language'],
      timezone: json['timezone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      totalHabits: json['total_habits'] ?? 0,
      challengesCompleted: json['challenges_completed'] ?? 0,
      totalFocusTime: json['total_focus_time'] ?? 0,
      favoriteQuote: json['favorite_quote'],
      primaryColor: json['primary_color'],
      theme: json['theme'],
      profileIcon: json['profile_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'country': country,
      'language': language,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'level': level,
      'xp': xp,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'total_habits': totalHabits,
      'challenges_completed': challengesCompleted,
      'total_focus_time': totalFocusTime,
      'favorite_quote': favoriteQuote,
      'primary_color': primaryColor,
      'theme': theme,
      'profile_icon': profileIcon,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bannerUrl,
    String? country,
    String? language,
    String? timezone,
    DateTime? createdAt,
    int? level,
    int? xp,
    int? currentStreak,
    int? bestStreak,
    int? totalHabits,
    int? challengesCompleted,
    int? totalFocusTime,
    String? favoriteQuote,
    String? primaryColor,
    String? theme,
    String? profileIcon,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      country: country ?? this.country,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalHabits: totalHabits ?? this.totalHabits,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      favoriteQuote: favoriteQuote ?? this.favoriteQuote,
      primaryColor: primaryColor ?? this.primaryColor,
      theme: theme ?? this.theme,
      profileIcon: profileIcon ?? this.profileIcon,
    );
  }

  int get xpForNextLevel => (level * 100) + ((level - 1) * 50);
  double get xpProgress => xp / xpForNextLevel;
  String get levelTitle {
    if (level >= 50) return 'Légende';
    if (level >= 40) return 'Maître';
    if (level >= 30) return 'Expert';
    if (level >= 20) return 'Avancé';
    if (level >= 10) return 'Intermédiaire';
    if (level >= 5) return 'Débutant';
    return 'Novice';
  }
}
