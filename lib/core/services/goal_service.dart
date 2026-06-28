import 'dart:convert';
import 'package:ascend/data/models/goal.dart';
import 'package:ascend/data/models/sub_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalService {
  static const String _goalsKey = 'goals_data';
  static List<Goal> _goals = [];

  static List<Goal> get goals => List.unmodifiable(_goals);

  static Future<void> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? goalsJson = prefs.getString(_goalsKey);
    if (goalsJson != null) {
      final List<dynamic> decoded = jsonDecode(goalsJson);
      _goals = decoded.map((g) => Goal.fromJson(g)).toList();
    } else {
      _goals = [];
    }
  }

  static Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_goals.map((g) => g.toJson()).toList());
    await prefs.setString(_goalsKey, encoded);
  }

  static Future<Goal> addGoal(Goal goal) async {
    _goals.add(goal);
    await _saveGoals();
    return goal;
  }

  static Future<void> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      await _saveGoals();
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    await _saveGoals();
  }

  static Future<void> addSubGoal(String goalId, SubGoal subGoal) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex].subGoals.add(subGoal);
      await _saveGoals();
    }
  }

  static Future<void> updateSubGoal(String goalId, SubGoal subGoal) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final subIndex = _goals[goalIndex].subGoals.indexWhere((s) => s.id == subGoal.id);
      if (subIndex != -1) {
        _goals[goalIndex].subGoals[subIndex] = subGoal;
        await _saveGoals();
      }
    }
  }

  static Future<void> deleteSubGoal(String goalId, String subGoalId) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex].subGoals.removeWhere((s) => s.id == subGoalId);
      await _saveGoals();
    }
  }

  static List<Goal> getActiveGoals() {
    return _goals.where((g) => g.status == GoalStatus.active).toList();
  }

  static List<Goal> getCompletedGoals() {
    return _goals.where((g) => g.status == GoalStatus.completed).toList();
  }

  static Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> completeGoal(String goalId) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      goal.status = GoalStatus.completed;
      goal.completedAt = DateTime.now();
      for (var subGoal in goal.subGoals) {
        if (!subGoal.isCompleted) {
          subGoal.isCompleted = true;
          subGoal.progression = 1.0;
          subGoal.completedAt = DateTime.now();
        }
      }
      await _saveGoals();
    }
  }

  static Future<void> pauseGoal(String goalId) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      goal.status = GoalStatus.paused;
      await _saveGoals();
    }
  }

  static Future<void> resumeGoal(String goalId) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      goal.status = GoalStatus.active;
      await _saveGoals();
    }
  }

  static Future<void> abandonGoal(String goalId) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      goal.status = GoalStatus.abandoned;
      await _saveGoals();
    }
  }
}
