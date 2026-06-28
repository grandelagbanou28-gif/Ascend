import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationService {
  static const String _dataKey = 'gamification_data';

  static int _xp = 0;
  static int _level = 1;
  static int _coins = 0;
  static List<String> _unlockedBadges = [];
  static List<String> _purchasedItems = [];

  static int get xp => _xp;
  static int get level => _level;
  static int get coins => _coins;
  static List<String> get unlockedBadges => List.unmodifiable(_unlockedBadges);

  static int get xpForNextLevel => _level * 100;
  static int get xpProgress => _xp % xpForNextLevel;
  static double get levelProgress => xpProgress / xpForNextLevel;

  static String get title {
    if (_level >= 50) return 'Légende';
    if (_level >= 40) return 'Maître';
    if (_level >= 30) return 'Expert';
    if (_level >= 20) return 'Discipliné';
    if (_level >= 10) return 'Novice';
    return 'Débutant';
  }

  static List<String> get titles => [
        'Débutant',
        'Novice',
        'Discipliné',
        'Expert',
        'Maître',
        'Légende',
      ];

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_dataKey);
    if (data != null) {
      final decoded = jsonDecode(data);
      _xp = decoded['xp'] ?? 0;
      _level = decoded['level'] ?? 1;
      _coins = decoded['coins'] ?? 0;
      _unlockedBadges = List<String>.from(decoded['badges'] ?? []);
      _purchasedItems = List<String>.from(decoded['purchased'] ?? []);
    }
  }

  static Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'xp': _xp,
      'level': _level,
      'coins': _coins,
      'badges': _unlockedBadges,
      'purchased': _purchasedItems,
    });
    await prefs.setString(_dataKey, data);
  }

  static Future<bool> addXp(int amount) async {
    _xp += amount;
    final oldLevel = _level;

    while (_xp >= xpForNextLevel) {
      _level++;
    }

    await _saveData();
    return _level > oldLevel;
  }

  static Future<void> addCoins(int amount) async {
    _coins += amount;
    await _saveData();
  }

  static Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    await _saveData();
    return true;
  }

  static Future<void> unlockBadge(String badgeId) async {
    if (!_unlockedBadges.contains(badgeId)) {
      _unlockedBadges.add(badgeId);
      await _saveData();
    }
  }

  static Future<void> purchaseItem(String itemId) async {
    if (!_purchasedItems.contains(itemId)) {
      _purchasedItems.add(itemId);
      await _saveData();
    }
  }

  static bool hasPurchased(String itemId) {
    return _purchasedItems.contains(itemId);
  }

  static bool hasBadge(String badgeId) {
    return _unlockedBadges.contains(badgeId);
  }

  static int getLevelXp(int level) => level * 100;
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredLevel;
  final int coinCost;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.requiredLevel = 0,
    this.coinCost = 0,
  });

  static List<Badge> all = [
    const Badge(
      id: 'first_habit',
      name: 'Premier Pas',
      description: 'Créer votre première habitude',
      icon: '🌟',
    ),
    const Badge(
      id: 'week_streak',
      name: 'Semaine Parfaite',
      description: 'Maintenir une série de 7 jours',
      icon: '🔥',
      requiredLevel: 3,
    ),
    const Badge(
      id: 'month_streak',
      name: 'Discipliné',
      description: 'Maintenir une série de 30 jours',
      icon: '💪',
      requiredLevel: 10,
    ),
    const Badge(
      id: 'first_challenge',
      name: 'Challenger',
      description: 'Terminer votre premier défi',
      icon: '🏆',
      requiredLevel: 5,
    ),
    const Badge(
      id: 'focus_master',
      name: 'Maître Focus',
      description: 'Accumuler 100 heures de focus',
      icon: '🧠',
      requiredLevel: 15,
    ),
    const Badge(
      id: 'journal_writer',
      name: 'Écrivain',
      description: 'Écrire 50 entrées de journal',
      icon: '📝',
      requiredLevel: 8,
    ),
    const Badge(
      id: 'early_bird',
      name: 'Lève-tôt',
      description: 'Compléter 10 habitudes avant 7h',
      icon: '🌅',
      requiredLevel: 12,
    ),
    const Badge(
      id: 'social_butterfly',
      name: 'Social',
      description: 'Ajouter 5 amis',
      icon: '🦋',
      requiredLevel: 7,
    ),
    const Badge(
      id: 'shopaholic',
      name: 'Collectionneur',
      description: 'Acheter 10 articles à la boutique',
      icon: '🛍️',
      requiredLevel: 10,
      coinCost: 500,
    ),
    const Badge(
      id: 'legend',
      name: 'Légende',
      description: 'Atteindre le niveau 50',
      icon: '👑',
      requiredLevel: 50,
    ),
  ];
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String type; // icon, badge, theme, animation, avatar
  final String preview;
  final int price;
  final int requiredLevel;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.preview,
    required this.price,
    this.requiredLevel = 0,
  });

  static List<ShopItem> all = [
    const ShopItem(
      id: 'icon_star',
      name: 'Icône Étoile',
      description: 'Une étoile dorée pour vos habitudes',
      type: 'icon',
      preview: '⭐',
      price: 50,
    ),
    const ShopItem(
      id: 'icon_fire',
      name: 'Icône Flamme',
      description: 'Une flamme pour motiver',
      type: 'icon',
      preview: '🔥',
      price: 50,
    ),
    const ShopItem(
      id: 'icon_heart',
      name: 'Icône Cœur',
      description: 'Un cœur pour les habitudes santé',
      type: 'icon',
      preview: '❤️',
      price: 50,
    ),
    const ShopItem(
      id: 'theme_night',
      name: 'Thème Nuit',
      description: 'Un thème sombre élégant',
      type: 'theme',
      preview: '🌙',
      price: 200,
      requiredLevel: 5,
    ),
    const ShopItem(
      id: 'theme_forest',
      name: 'Thème Forêt',
      description: 'Un thème vert naturel',
      type: 'theme',
      preview: '🌲',
      price: 200,
      requiredLevel: 5,
    ),
    const ShopItem(
      id: 'theme_ocean',
      name: 'Thème Océan',
      description: 'Un thème bleu apaisant',
      type: 'theme',
      preview: '🌊',
      price: 200,
      requiredLevel: 5,
    ),
    const ShopItem(
      id: 'anim_confetti',
      name: 'Confettis',
      description: 'Confettis quand vous complétez une tâche',
      type: 'animation',
      preview: '🎉',
      price: 300,
      requiredLevel: 10,
    ),
    const ShopItem(
      id: 'anim_sparkle',
      name: 'Étincelles',
      description: 'Étincelles magiques',
      type: 'animation',
      preview: '✨',
      price: 300,
      requiredLevel: 10,
    ),
    const ShopItem(
      id: 'avatar_cat',
      name: 'Avatar Chat',
      description: 'Un avatar mignon',
      type: 'avatar',
      preview: '🐱',
      price: 150,
    ),
    const ShopItem(
      id: 'avatar_dog',
      name: 'Avatar Chien',
      description: 'Un avatar fidèle',
      type: 'avatar',
      preview: '🐶',
      price: 150,
    ),
  ];
}
