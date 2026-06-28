import 'dart:convert';
import 'package:ascend/data/models/challenge.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengeService {
  static const String _challengesKey = 'challenges_data';
  static List<Challenge> _challenges = [];

  static List<Challenge> get challenges => List.unmodifiable(_challenges);

  static Future<void> loadChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final String? challengesJson = prefs.getString(_challengesKey);
    if (challengesJson != null) {
      final List<dynamic> decoded = jsonDecode(challengesJson);
      _challenges = decoded.map((c) => Challenge.fromJson(c)).toList();
    } else {
      _challenges = [];
    }
  }

  static Future<void> _saveChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_challenges.map((c) => c.toJson()).toList());
    await prefs.setString(_challengesKey, encoded);
  }

  static Future<Challenge> addChallenge(Challenge challenge) async {
    _challenges.add(challenge);
    await _saveChallenges();
    return challenge;
  }

  static Future<void> updateChallenge(Challenge challenge) async {
    final index = _challenges.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      _challenges[index] = challenge;
      await _saveChallenges();
    }
  }

  static Future<void> deleteChallenge(String challengeId) async {
    _challenges.removeWhere((c) => c.id == challengeId);
    await _saveChallenges();
  }

  static Challenge? getChallengeById(String id) {
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Challenge> getActiveChallenges() {
    return _challenges.where((c) => c.status == ChallengeStatus.active).toList();
  }

  static List<Challenge> getCompletedChallenges() {
    return _challenges.where((c) => c.status == ChallengeStatus.completed).toList();
  }

  static List<Challenge> getAvailableChallenges() {
    return _challenges.where((c) => c.status == ChallengeStatus.available).toList();
  }

  static Future<void> startChallenge(String challengeId) async {
    final challenge = getChallengeById(challengeId);
    if (challenge != null) {
      challenge.status = ChallengeStatus.active;
      challenge.startDate = DateTime.now();
      await _saveChallenges();
    }
  }

  static Future<void> completeDay(String challengeId, DateTime date) async {
    final challenge = getChallengeById(challengeId);
    if (challenge != null && challenge.isActive) {
      final dateStr = date.toIso8601String().substring(0, 10);
      if (!challenge.completedDays.contains(dateStr)) {
        challenge.completedDays.add(dateStr);
        challenge.daysCompleted++;
        await _saveChallenges();
      }
    }
  }

  static Future<void> completeChallenge(String challengeId) async {
    final challenge = getChallengeById(challengeId);
    if (challenge != null) {
      challenge.status = ChallengeStatus.completed;
      challenge.completedAt = DateTime.now();
      await _saveChallenges();
    }
  }

  static Future<void> failChallenge(String challengeId) async {
    final challenge = getChallengeById(challengeId);
    if (challenge != null) {
      challenge.status = ChallengeStatus.failed;
      await _saveChallenges();
    }
  }

  static bool isCompletedToday(Challenge challenge) {
    if (!challenge.isActive) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return challenge.completedDays.contains(today);
  }

  static int getTotalXpEarned() {
    return _challenges
        .where((c) => c.status == ChallengeStatus.completed)
        .fold<int>(0, (sum, c) => sum + c.xpReward);
  }
}
