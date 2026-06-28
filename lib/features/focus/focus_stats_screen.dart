import 'package:flutter/material.dart';
import 'package:ascend/data/models/focus_session.dart';
import 'package:ascend/core/services/focus_service.dart';
import 'package:fl_chart/fl_chart.dart';

class FocusStatsScreen extends StatefulWidget {
  const FocusStatsScreen({super.key});

  @override
  State<FocusStatsScreen> createState() => _FocusStatsScreenState();
}

class _FocusStatsScreenState extends State<FocusStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSessions = FocusService.getTotalSessions();
    final totalMinutes = FocusService.getTotalMinutes();
    final totalXp = FocusService.getTotalXpEarned();
    final streak = FocusService.getCurrentStreak();
    final sessionsByDay = FocusService.getSessionsByDay();
    final sessionsByMode = FocusService.getSessionsByMode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Focus',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(theme, totalSessions, totalMinutes, totalXp, streak),
          const SizedBox(height: 24),
          _buildWeeklyChart(theme, sessionsByDay),
          const SizedBox(height: 24),
          _buildModeDistribution(theme, sessionsByMode),
          const SizedBox(height: 24),
          _buildBestSession(theme),
          const SizedBox(height: 24),
          _buildRecentSessions(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, int sessions, int minutes, int xp, int streak) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(theme, Icons.timer, 'Sessions', '$sessions', Colors.blue),
        _buildStatCard(theme, Icons.access_time, 'Minutes', '$minutes', Colors.green),
        _buildStatCard(theme, Icons.star, 'XP Total', '$xp', Colors.orange),
        _buildStatCard(theme, Icons.local_fire_department, 'Série', '$streak jours', Colors.red),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, Map<String, int> sessionsByDay) {
    final now = DateTime.now();
    final days = <String>[];
    final values = <double>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayName = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'][date.weekday % 7];
      days.add(dayName);
      values.add((sessionsByDay[key] ?? 0).toDouble());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette semaine',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: values.isEmpty
                      ? 10
                      : (values.reduce((a, b) => a > b ? a : b) * 1.2),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(days[index],
                                style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}m',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          color: theme.colorScheme.primary,
                          width: 20,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeDistribution(ThemeData theme, Map<String, int> sessionsByMode) {
    if (sessionsByMode.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distribution par mode',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Center(child: Text('Aucune donnée')),
            ],
          ),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distribution par mode',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sessionsByMode.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final mode = entry.value.key;
              final minutes = entry.value.value;
              final color = colors[index % colors.length];
              final total = sessionsByMode.values.fold<int>(0, (s, v) => s + v);
              final percentage = total > 0 ? (minutes / total * 100).round() : 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(mode)),
                    Text('$minutes min ($percentage%)',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSession(ThemeData theme) {
    final sessions = FocusService.sessions;
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final best = sessions.reduce((a, b) =>
        a.actualMinutes > b.actualMinutes ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meilleure session',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${best.actualMinutes} minutes',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${best.mode.displayName} • ${best.xpEarned} XP'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(ThemeData theme) {
    final sessions = List<FocusSession>.from(FocusService.sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final recent = sessions.take(5).toList();

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sessions récentes',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...recent.map((session) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(session.mode.displayName,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text('${session.actualMinutes} minutes'),
                  subtitle: Text(
                      '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}'),
                  trailing: Text('${session.xpEarned} XP',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                )),
          ],
        ),
      ),
    );
  }
}
