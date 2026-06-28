import 'dart:convert';
import 'package:ascend/data/models/focus_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusService {
  static const String _sessionsKey = 'focus_sessions_data';
  static List<FocusSession> _sessions = [];

  static List<FocusSession> get sessions => List.unmodifiable(_sessions);

  static Future<void> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString(_sessionsKey);
    if (sessionsJson != null) {
      final List<dynamic> decoded = jsonDecode(sessionsJson);
      _sessions = decoded.map((s) => FocusSession.fromJson(s)).toList();
    } else {
      _sessions = [];
    }
  }

  static Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  static Future<FocusSession> addSession(FocusSession session) async {
    _sessions.add(session);
    await _saveSessions();
    return session;
  }

  static Future<void> updateSession(FocusSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      await _saveSessions();
    }
  }

  static Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions();
  }

  static List<FocusSession> getCompletedSessions() {
    return _sessions
        .where((s) => s.status == FocusSessionStatus.completed)
        .toList();
  }

  static List<FocusSession> getTodaySessions() {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.startTime.year == now.year &&
          s.startTime.month == now.month &&
          s.startTime.day == now.day;
    }).toList();
  }

  static int getTodayTotalMinutes() {
    return getTodaySessions().fold<int>(0, (sum, s) => sum + s.actualMinutes);
  }

  static int getTodayXpEarned() {
    return getTodaySessions().fold<int>(0, (sum, s) => sum + s.xpEarned);
  }

  static int getTotalMinutes() {
    return _sessions.fold<int>(0, (sum, s) => sum + s.actualMinutes);
  }

  static int getTotalXpEarned() {
    return _sessions.fold<int>(0, (sum, s) => sum + s.xpEarned);
  }

  static int getTotalSessions() {
    return _sessions.length;
  }

  static Map<String, int> getSessionsByDay() {
    final Map<String, int> result = {};
    for (var session in _sessions) {
      final dateKey =
          '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
      result[dateKey] = (result[dateKey] ?? 0) + session.actualMinutes;
    }
    return result;
  }

  static Map<String, int> getSessionsByMode() {
    final Map<String, int> result = {};
    for (var session in _sessions) {
      final mode = session.mode.displayName;
      result[mode] = (result[mode] ?? 0) + session.actualMinutes;
    }
    return result;
  }

  static int getCurrentStreak() {
    if (_sessions.isEmpty) return 0;

    final sortedSessions = List<FocusSession>.from(_sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    DateTime? lastDate;

    for (var session in sortedSessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (lastDate == null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        if (sessionDate == todayDate ||
            sessionDate == todayDate.subtract(Duration(days: 1))) {
          lastDate = sessionDate;
          streak++;
        } else {
          break;
        }
      } else {
        final diff = lastDate.difference(sessionDate).inDays;
        if (diff == 1) {
          lastDate = sessionDate;
          streak++;
        } else if (diff > 1) {
          break;
        }
      }
    }

    return streak;
  }
}
