import 'package:flutter/material.dart';
import 'package:ascend/data/models/habit.dart';

class GamificationDisplay extends StatelessWidget {
  final Habit habit;
  final bool isCompact;
  
  const GamificationDisplay({
    super.key,
    required this.habit,
    this.isCompact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactDisplay(context);
    } else {
      return _buildFullDisplay(context);
    }
  }
  
  Widget _buildCompactDisplay(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Completions
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 12, color: Colors.amber),
              SizedBox(width: 2),
              Text(
                '${habit.totalCompletions}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFullDisplay(BuildContext context) {
    final successRate = habit.entries.isEmpty
        ? 0.0
        : (habit.totalCompletions / habit.entries.length * 100);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${habit.totalCompletions} Total Completions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Streak',
                  '${habit.currentStreak}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  'Success',
                  '${successRate.toStringAsFixed(0)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  'Entries',
                  '${habit.entries.length}',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to add gamification display to HabitListItem
extension GamificationExtension on Widget {
  Widget withGamification(Habit habit, {bool compact = true}) {
    return Column(
      children: [
        this,
        if (habit.totalCompletions > 0) ...[
          SizedBox(height: 8),
          GamificationDisplay(habit: habit, isCompact: compact),
        ],
      ],
    );
  }
}
