import 'package:flutter/material.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/data/models/habit.dart';
import 'package:ascend/features/habits/add_entry_dialog.dart';
import 'package:ascend/data/models/habit_entry.dart';
import 'package:ascend/core/services/storage_service.dart';
import 'package:ascend/core/services/data_service.dart';
import 'package:ascend/core/services/reports_service.dart';
import 'package:intl/intl.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});
  
  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _refreshHabit() {
    setState(() {});
  }
  
  int _getNextDayNumber() {
    final entries = widget.habit.entries;
    if (entries.isEmpty) return 1;
    return entries.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
  }
  
  void _showAddEntryDialog() {
    final nextDay = _getNextDayNumber();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        child: AddEntryDialog(
          habit: widget.habit,
          dayNumber: nextDay,
          onSave: (entry) async {
            widget.habit.entries.add(entry);
            await StorageService.save(widget.habit);
            Navigator.of(context).pop();
            _refreshHabit();
          },
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Habit Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.code, color: Colors.blue),
              title: Text('Export as JSON'),
              subtitle: Text('Complete data including all entries and metadata'),
              onTap: () async {
                try {
                  final jsonData = await DataService.exportHabitToJson(widget.habit);
                  final filename = '${widget.habit.name}_export_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
                  await DataService.shareData(jsonData, filename, 'application/json');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Data exported successfully!')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.green),
              title: Text('Generate Report'),
              subtitle: Text('Detailed summary report for this habit'),
              onTap: () async {
                try {
                  final report = await DataService.generateSummaryReport([widget.habit]);
                  final filename = '${widget.habit.name}_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.txt';
                  await DataService.shareData(report, filename, 'text/plain');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report generated successfully!')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report generation failed: $e')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do with "${widget.habit.formattedName}"?'),
            SizedBox(height: 16),
            if (!widget.habit.isPaused) ListTile(
              leading: Icon(Icons.pause_circle, color: Colors.orange),
              title: Text('Pause Habit'),
              subtitle: Text('Temporarily stop tracking without affecting streaks'),
              onTap: () async {
                widget.habit.isPaused = true;
                await StorageService.save(widget.habit);
                Navigator.pop(context);
                _refreshHabit();
              },
            ),
            if (widget.habit.isPaused) ListTile(
              leading: Icon(Icons.play_circle, color: Colors.green),
              title: Text('Resume Habit'),
              subtitle: Text('Continue tracking this habit'),
              onTap: () async {
                widget.habit.isPaused = false;
                await StorageService.save(widget.habit);
                Navigator.pop(context);
                _refreshHabit();
              },
            ),
            if (!widget.habit.isArchived) ListTile(
              leading: Icon(Icons.archive, color: Colors.amber),
              title: Text('Archive Habit'),
              subtitle: Text('Hide it from the main list but keep the data'),
              onTap: () async {
                widget.habit.isArchived = true;
                await StorageService.save(widget.habit);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            if (widget.habit.isArchived) ListTile(
              leading: Icon(Icons.unarchive, color: Colors.green),
              title: Text('Restore Habit'),
              subtitle: Text('Bring it back to the active list'),
              onTap: () async {
                widget.habit.isArchived = false;
                await StorageService.save(widget.habit);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Delete Permanently'),
              subtitle: Text('This cannot be undone'),
              onTap: () {
                _confirmDelete();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete "${widget.habit.formattedName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await StorageService.delete(widget.habit);
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.formattedName),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.history), text: 'Entries'),
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.assessment), text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showDeleteHabitDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEntriesTab(),
          _buildOverviewTab(),
          _buildCalendarTab(),
          _buildAnalyticsTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        tooltip: 'Add Entry',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakCard(),
          SizedBox(height: 16),
          _buildHabitInfoCard(),
          SizedBox(height: 16),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 16),
          Text(
            'Calendar view is currently disabled',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuccessRateChart(),
          SizedBox(height: 24),
          _buildStreakTrendChart(),
          SizedBox(height: 24),
          _buildPerformanceInsights(),
        ],
      ),
    );
  }
  
  Widget _buildSuccessRateChart() {
    final habit = widget.habit;
    if (habit.entries.isEmpty) {
      return _buildEmptyChartCard('Success Rate', 'Add entries to see your success rate chart');
    }
    
    final now = DateTime.now();
    final groupedEntries = <DateTime, List<HabitEntry>>{};
    
    for (var i = 0; i < 8; i++) {
      final weekStart = now.subtract(Duration(days: 7 * i + now.weekday - 1));
      final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
      groupedEntries[key] = [];
    }
    
    for (var entry in habit.entries) {
      final entryDate = entry.date;
      final weekStart = entryDate.subtract(Duration(days: entryDate.weekday - 1));
      final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      if (groupedEntries.containsKey(key)) {
        groupedEntries[key]!.add(entry);
      }
    }
    
    final chartData = <DateTime, double>{};
    groupedEntries.forEach((date, entries) {
      if (entries.isNotEmpty) {
        final successCount = entries.where((e) => e.count > 0).length;
        final rate = (successCount / entries.length) * 100;
        chartData[date] = rate;
      } else {
        chartData[date] = 0;
      }
    });
    
    final sortedDates = chartData.keys.toList()..sort((a, b) => a.compareTo(b));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Success Rate Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('75%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('50%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('25%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: sortedDates.map((date) {
                        final value = chartData[date] ?? 0;
                        final barHeight = value * 1.8;
                        
                        return Tooltip(
                          message: '${DateFormat('MMM d').format(date)}: ${value.toStringAsFixed(1)}%',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 24,
                                height: barHeight.clamp(4, 180),
                                decoration: BoxDecoration(
                                  color: _getSuccessRateColor(value),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('d/M').format(date),
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getSuccessRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 40) return Colors.amber;
    if (rate >= 20) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildStreakTrendChart() {
    final habit = widget.habit;
    
    if (habit.entries.isEmpty) {
      return _buildEmptyChartCard('Streak Trends', 'Add entries to see your streak trends');
    }
    
    final currentStreak = habit.currentStreak;
    final bestStreak = habit.bestStreak;
    final negativeCount = habit.entries.where((e) => e.count <= 0).length;
    final avgStreak = habit.entries.length / (negativeCount > 0 ? negativeCount + 1 : 1);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streak Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStreakMetric('Current', currentStreak, Icons.local_fire_department, 
                  currentStreak > 0 ? Colors.orange : Colors.grey),
                _buildStreakMetric('Best', bestStreak, Icons.emoji_events, 
                  bestStreak > 0 ? Colors.amber : Colors.grey),
                _buildStreakMetric('Average', avgStreak.round(), Icons.bar_chart, 
                  avgStreak > 0 ? Colors.blue : Colors.grey),
              ],
            ),
            SizedBox(height: 16),
            if (currentStreak > 0 && bestStreak > 0)
              LinearProgressIndicator(
                value: currentStreak / bestStreak,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: _getStreakProgressColor(currentStreak, bestStreak),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            if (currentStreak > 0 && bestStreak > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${(currentStreak / bestStreak * 100).round()}% of your best streak',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStreakMetric(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Color _getStreakProgressColor(int current, int best) {
    final ratio = current / best;
    if (ratio >= 0.9) return Colors.green;
    if (ratio >= 0.7) return Colors.lightGreen;
    if (ratio >= 0.5) return Colors.amber;
    if (ratio >= 0.3) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildPerformanceInsights() {
    final habit = widget.habit;
    
    if (habit.entries.isEmpty) {
      return _buildEmptyChartCard('Performance Insights', 'Add entries to see performance insights');
    }
    
    final insights = _generateInsights(habit);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight['color'].withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(insight['icon'], color: insight['color'], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  insight['description'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _generateInsights(Habit habit) {
    List<Map<String, dynamic>> insights = [];
    
    if (habit.entries.length >= 5) {
      final successRate = (habit.entries.where((e) => e.count > 0).length / habit.entries.length) * 100;
      String rateDescription;
      Color rateColor;
      
      if (successRate >= 90) {
        rateDescription = 'Excellent! You\'re crushing this habit.';
        rateColor = Colors.green;
      } else if (successRate >= 70) {
        rateDescription = 'Good progress! Keep up the momentum.';
        rateColor = Colors.lightGreen;
      } else if (successRate >= 50) {
        rateDescription = 'You\'re doing okay. Room for improvement.';
        rateColor = Colors.amber;
      } else {
        rateDescription = 'This habit seems challenging. Consider adjusting your approach.';
        rateColor = Colors.orange;
      }
      
      insights.add({
        'title': 'Success Rate: ${successRate.toStringAsFixed(1)}%',
        'description': rateDescription,
        'icon': Icons.percent,
        'color': rateColor,
      });
    }
    
    if (habit.currentStreak > 0) {
      String streakDescription;
      Color streakColor;
      
      if (habit.currentStreak >= habit.bestStreak) {
        streakDescription = 'You\'re on your best streak ever! Amazing work!';
        streakColor = Colors.purple;
      } else if (habit.currentStreak >= habit.bestStreak * 0.7) {
        streakDescription = 'Getting close to your best streak! Keep going!';
        streakColor = Colors.blue;
      } else {
        streakDescription = 'Good progress on your current streak.';
        streakColor = Colors.teal;
      }
      
      insights.add({
        'title': '${habit.currentStreak}-Day Streak',
        'description': streakDescription,
        'icon': Icons.local_fire_department,
        'color': streakColor,
      });
    }
    
    if (habit.entries.length >= 7) {
      final dayCount = <int, int>{};
      for (var entry in habit.entries) {
        final day = entry.date.weekday;
        dayCount[day] = (dayCount[day] ?? 0) + 1;
      }
      
      final mostActiveDay = dayCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      insights.add({
        'title': 'Most Active Day',
        'description': '${dayNames[mostActiveDay.key - 1]} is your most consistent day',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      });
    }
    
    return insights;
  }
  
  Widget _buildEmptyChartCard(String title, String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entry History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (widget.habit.entries.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No entries yet', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap the + button to add your first entry', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            ..._buildEntriesList(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports & Insights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildReportsCards(),
        ],
      ),
    );
  }

  Widget _buildReportsCards() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Icon(Icons.calendar_month, color: Colors.blue),
            ),
            title: Text('${DateFormat('MMMM yyyy').format(now)} Report'),
            subtitle: Text('Monthly summary and trends'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              final monthReport = ReportsService.generateMonthlyReport([widget.habit], currentYear, currentMonth);
              _showMonthlyReportDialog(monthReport);
            },
          ),
        ),
        SizedBox(height: 8),
        
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: Icon(Icons.auto_awesome, color: Colors.green),
            ),
            title: Text('$currentYear Year in Review'),
            subtitle: Text('Your habit journey this year'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              final yearReview = ReportsService.generateYearInReview([widget.habit], currentYear);
              _showYearInReviewDialog(yearReview);
            },
          ),
        ),
        SizedBox(height: 8),
        
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Icon(Icons.view_week, color: Colors.orange),
            ),
            title: Text('This Week Report'),
            subtitle: Text('Recent 7-day performance'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              final weekReport = ReportsService.generateWeeklyReport([widget.habit], weekStart);
              _showWeeklyReportDialog(weekReport);
            },
          ),
        ),
      ],
    );
  }

  void _showMonthlyReportDialog(MonthlyReportData report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${report.monthName} ${report.year} Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Entries: ${report.totalEntries}'),
              Text('Average Success Rate: ${report.averageSuccessRate.toStringAsFixed(1)}%'),
              SizedBox(height: 16),
              if (report.trends.isNotEmpty) ...[
                Text('Trends:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...report.trends.map((trend) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${trend.title}: ${trend.description}'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showYearInReviewDialog(YearInReviewData review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${review.year} Year in Review'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Entries: ${review.totalEntries}'),
              Text('Days Tracked: ${review.totalDaysTracked}'),
              Text('Success Rate: ${review.overallSuccessRate.toStringAsFixed(1)}%'),
              Text('Longest Streak: ${review.longestStreak} days'),
              SizedBox(height: 16),
              if (review.milestones.isNotEmpty) ...[
                Text('Milestones:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...review.milestones.take(3).map((milestone) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${milestone.title} (${DateFormat('MMM d').format(milestone.date)})'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWeeklyReportDialog(WeeklyReportData report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Weekly Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Period: ${DateFormat('MMM d').format(report.weekStart)} - ${DateFormat('MMM d').format(report.weekEnd)}'),
              Text('Total Entries: ${report.totalEntries}'),
              Text('Average Success Rate: ${report.averageSuccessRate.toStringAsFixed(1)}%'),
              SizedBox(height: 16),
              if (report.bestDay != null) 
                Text('Best Day: ${DateFormat('EEEE').format(report.bestDay!.date)} (${report.bestDay!.successRate.toStringAsFixed(1)}%)'),
              if (report.worstDay != null) 
                Text('Challenging Day: ${DateFormat('EEEE').format(report.worstDay!.date)} (${report.worstDay!.successRate.toStringAsFixed(1)}%)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitInfoCard() {
    final habit = widget.habit;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Type', habit.typeDisplayName),
            _buildInfoRow('Frequency', habit.frequencyDisplayName),
            _buildInfoRow('Category', habit.categoryDisplayName),
            if (habit.targetValue != null)
              _buildInfoRow('Target', '${habit.targetValue} ${habit.targetUnit ?? ''}'),
            if (habit.isPaused)
              _buildInfoRow('Status', 'Paused', color: Colors.orange),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    final habit = widget.habit;
    final entries = habit.entries;
    
    final days = entries.length;
    final totalCount = entries.fold(0, (sum, e) => sum + e.count);
    final positiveDays = entries.where((e) => e.count > 0).length;
    final negativeDays = days - positiveDays;
    
    final avgPerDay = days > 0 ? totalCount / days : 0;
    final avgPositive = positiveDays > 0
        ? entries
            .where((e) => e.count > 0)
            .fold(0, (sum, e) => sum + e.count) / positiveDays
        : 0;
    
    final maxCount = entries.isEmpty ? 0 : entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final maxDays = entries.where((e) => e.count == maxCount).map((e) => e.dayNumber).toList();
    
    return Column(
      children: [
        _buildStatItem('Total Days Tracked', days.toString()),
        _buildStatItem('Total Count Sum', '$totalCount'),
        _buildStatItem('Average Count per Day', avgPerDay.toStringAsFixed(2)),
        if (maxCount > 0)
          _buildStatItem('Highest Count ($maxCount) on Day(s)', maxDays.join(', ')),
      ],
    );
  }
  
  Widget _buildStreakCard() {
    final habit = widget.habit;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              Theme.of(context).colorScheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${habit.currentStreak}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'days',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Best Streak',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${habit.bestStreak}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'days',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEntriesList() {
    final entries = widget.habit.entries;
    
    final sortedEntries = [...entries]..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
    
    return sortedEntries.map((entry) {
      final isPositive = entry.count > 0;
      
      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: entry.isSkipped 
                ? Colors.orange.withValues(alpha: 0.2)
                : isPositive 
                    ? Colors.green.withValues(alpha: 0.2) 
                    : Colors.red.withValues(alpha: 0.2),
            foregroundColor: entry.isSkipped 
                ? Colors.orange
                : isPositive 
                    ? Colors.green 
                    : Colors.red,
            child: Icon(entry.isSkipped 
                ? Icons.skip_next
                : isPositive 
                    ? Icons.check 
                    : Icons.close),
          ),
          title: Text(
            'Day ${entry.dayNumber}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(entry.date),
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(_getEntryDescription(entry)),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Entry'),
                  content: Text('Are you sure you want to delete this entry?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await StorageService.deleteEntry(widget.habit, entry);
                _refreshHabit();
              }
            },
          ),
        ),
      );
    }).toList();
  }

  String _getEntryDescription(HabitEntry entry) {
    if (entry.isSkipped) {
      return 'Skipped day';
    }
    
    String description;
    switch (widget.habit.type) {
      case HabitType.Negative:
        if (entry.value != null) {
          description = entry.count == 0 
              ? 'Success (0 ${widget.habit.targetUnit ?? ''})' 
              : '${entry.value} ${entry.unit ?? widget.habit.targetUnit ?? ''}';
        } else {
          description = entry.count == 0 
              ? 'Success (0 failures)' 
              : '${entry.count} failure(s)';
        }
        break;
      case HabitType.Positive:
        if (entry.value != null) {
          description = entry.count > 0 
              ? '${entry.value} ${entry.unit ?? widget.habit.targetUnit ?? ''}' 
              : 'Failed (0 ${widget.habit.targetUnit ?? ''})';
        } else {
          description = entry.count > 0 
              ? '${entry.count} success(es)' 
              : 'Failed (0 successes)';
        }
        break;
      case HabitType.Counting:
        if (entry.value != null) {
          description = entry.count > 0 
              ? 'Completed (${entry.value} ${entry.unit ?? widget.habit.targetUnit ?? ''})' 
              : 'Not completed';
        } else {
          description = entry.count > 0 ? 'Completed' : 'Not completed';
        }
        break;
      case HabitType.Measurable:
        if (entry.value != null) {
          description = entry.count > 0 
              ? '${entry.value} ${entry.unit ?? widget.habit.targetUnit ?? ''}' 
              : 'No measurement recorded';
        } else {
          description = entry.count > 0 ? 'Recorded' : 'No data';
        }
        break;
      case HabitType.Timed:
        if (entry.value != null) {
          description = entry.count > 0 
              ? '${entry.value} ${entry.unit ?? widget.habit.targetUnit ?? 'minutes'}' 
              : 'No time recorded';
        } else {
          description = entry.count > 0 ? 'Timed activity' : 'No data';
        }
        break;
    }
    
    if (entry.notes != null && entry.notes!.isNotEmpty) {
      description += '\nNote: ${entry.notes}';
    }
    
    return description;
  }
}
