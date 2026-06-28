import 'package:flutter/material.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/data/models/habit.dart';
import 'package:ascend/core/services/storage_service.dart';
import 'package:fl_chart/fl_chart.dart';

enum TimeFilter { today, thisWeek, thisMonth, thisYear, all }
enum ChartType { bar, line, pie, radar }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  TimeFilter _selectedTimeFilter = TimeFilter.thisWeek;
  ChartType _selectedChartType = ChartType.bar;
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final habits = await StorageService.loadAll();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  List<Habit> get _filteredHabits {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _habits.where((h) {
      switch (_selectedTimeFilter) {
        case TimeFilter.today:
          return h.entries.any((e) =>
              e.date.year == today.year &&
              e.date.month == today.month &&
              e.date.day == today.day);
        case TimeFilter.thisWeek:
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          return h.entries
              .any((e) => e.date.isAfter(weekStart.subtract(const Duration(days: 1))));
        case TimeFilter.thisMonth:
          return h.entries
              .any((e) => e.date.month == now.month && e.date.year == now.year);
        case TimeFilter.thisYear:
          return h.entries.any((e) => e.date.year == now.year);
        case TimeFilter.all:
          return true;
      }
    }).toList();
  }

  int get _activeHabitsCount =>
      _filteredHabits.where((h) => !h.isArchived && !h.isPaused).length;

  double get _successRate {
    if (_filteredHabits.isEmpty) return 0.0;
    int totalEntries = 0;
    int completedEntries = 0;
    for (final habit in _filteredHabits) {
      for (final entry in habit.entries) {
        if (_isEntryInFilter(entry.date)) {
          totalEntries++;
          if (entry.count > 0) completedEntries++;
        }
      }
    }
    return totalEntries > 0 ? (completedEntries / totalEntries) * 100 : 0.0;
  }

  bool _isEntryInFilter(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedTimeFilter) {
      case TimeFilter.today:
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      case TimeFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(days: 1)));
      case TimeFilter.thisMonth:
        return date.month == now.month && date.year == now.year;
      case TimeFilter.thisYear:
        return date.year == now.year;
      case TimeFilter.all:
        return true;
    }
  }

  int get _currentStreak {
    int maxStreak = 0;
    for (final habit in _filteredHabits) {
      if (habit.currentStreak > maxStreak) {
        maxStreak = habit.currentStreak;
      }
    }
    return maxStreak;
  }

  int get _totalFocusMinutes {
    int total = 0;
    for (final habit in _filteredHabits) {
      if (habit.type == HabitType.Timed) {
        for (final entry in habit.entries) {
          if (entry.value != null && _isEntryInFilter(entry.date)) {
            total += entry.value!.toInt();
          }
        }
      } else {
        total += habit.durationMinutes * habit.totalCompletions;
      }
    }
    return total;
  }

  Map<HabitCategory, int> get _categoryBreakdown {
    final breakdown = <HabitCategory, int>{};
    for (final habit in _filteredHabits) {
      final completed = habit.entries
          .where((e) => e.count > 0 && _isEntryInFilter(e.date))
          .length;
      breakdown[habit.category] = (breakdown[habit.category] ?? 0) + completed;
    }
    return breakdown;
  }

  Map<String, int> get _completionsByDay {
    final now = DateTime.now();
    final completions = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _formatDate(date);
      completions[key] = 0;
    }

    for (final habit in _filteredHabits) {
      for (final entry in habit.entries) {
        if (entry.count > 0 && _isEntryInFilter(entry.date)) {
          final key = _formatDate(entry.date);
          if (completions.containsKey(key)) {
            completions[key] = completions[key]! + 1;
          }
        }
      }
    }
    return completions;
  }

  List<int> get _trendData {
    final now = DateTime.now();
    final data = <int>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      int count = 0;
      for (final habit in _filteredHabits) {
        for (final entry in habit.entries) {
          if (entry.count > 0 &&
              entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day) {
            count++;
          }
        }
      }
      data.add(count);
    }
    return data;
  }

  Map<String, double> get _successBreakdown {
    int success = 0;
    int fail = 0;
    int partial = 0;

    for (final habit in _filteredHabits) {
      for (final entry in habit.entries) {
        if (_isEntryInFilter(entry.date)) {
          if (entry.count > 0) {
            success++;
          } else if (entry.isSkipped) {
            partial++;
          } else {
            fail++;
          }
        }
      }
    }

    final total = success + fail + partial;
    if (total == 0) return {'Réussite': 0, 'Échec': 0, 'Partiel': 0};

    return {
      'Réussite': success / total * 100,
      'Échec': fail / total * 100,
      'Partiel': partial / total * 100,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTimeFilterChips(theme),
                const SizedBox(height: 16),
                _buildSummaryCards(theme),
                const SizedBox(height: 24),
                _buildChartTypeSelector(theme),
                const SizedBox(height: 16),
                _buildChartSection(theme),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(theme),
                const SizedBox(height: 24),
                _buildRecentActivity(theme),
              ],
            ),
    );
  }

  Widget _buildTimeFilterChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip('Aujourd\'hui', TimeFilter.today, theme),
        _buildFilterChip('Cette semaine', TimeFilter.thisWeek, theme),
        _buildFilterChip('Ce mois', TimeFilter.thisMonth, theme),
        _buildFilterChip('Cette année', TimeFilter.thisYear, theme),
        _buildFilterChip('Tout', TimeFilter.all, theme),
      ],
    );
  }

  Widget _buildFilterChip(String label, TimeFilter filter, ThemeData theme) {
    return FilterChip(
      label: Text(label),
      selected: _selectedTimeFilter == filter,
      onSelected: (selected) {
        setState(() {
          _selectedTimeFilter = filter;
        });
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(theme, Icons.check_circle, 'Habits actifs',
            '$_activeHabitsCount', Colors.blue),
        _buildStatCard(theme, Icons.trending_up, 'Taux de réussite',
            '${_successRate.toStringAsFixed(0)}%', Colors.green),
        _buildStatCard(theme, Icons.local_fire_department, 'Série actuelle',
            '$_currentStreak jours', Colors.orange),
        _buildStatCard(theme, Icons.timer, 'Temps total focus',
            '${_totalFocusMinutes}min', Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, IconData icon, String label,
      String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: [
        _buildChartChip('Barres', ChartType.bar, theme),
        _buildChartChip('Lignes', ChartType.line, theme),
        _buildChartChip('Camembert', ChartType.pie, theme),
        _buildChartChip('Radar', ChartType.radar, theme),
      ],
    );
  }

  Widget _buildChartChip(String label, ChartType type, ThemeData theme) {
    return FilterChip(
      label: Text(label),
      selected: _selectedChartType == type,
      onSelected: (selected) {
        setState(() {
          _selectedChartType = type;
        });
      },
      selectedColor: theme.colorScheme.secondaryContainer,
      checkmarkColor: theme.colorScheme.onSecondaryContainer,
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Graphiques',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 250, child: _buildChart(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    switch (_selectedChartType) {
      case ChartType.bar:
        return _buildBarChart(theme);
      case ChartType.line:
        return _buildLineChart(theme);
      case ChartType.pie:
        return _buildPieChart(theme);
      case ChartType.radar:
        return _buildRadarChart(theme);
    }
  }

  Widget _buildBarChart(ThemeData theme) {
    final data = _completionsByDay;
    final labels = data.keys.toList();
    final values = data.values.map((v) => v.toDouble()).toList();
    final maxY =
        values.isEmpty ? 10.0 : (values.reduce((a, b) => a > b ? a : b) * 1.2);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(labels[index],
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
                return Text('${value.toInt()}',
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
        barGroups: List.generate(values.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: theme.colorScheme.primary,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(ThemeData theme) {
    final data = _trendData;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index % 5 == 0 && index < data.length) {
                  return Text('${30 - index}j',
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
                return Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.toDouble());
            }).toList(),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(ThemeData theme) {
    final data = _successBreakdown;
    final colors = [Colors.green, Colors.red, Colors.orange];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: data.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value.value;
                return PieChartSectionData(
                  value: value,
                  title: value > 5 ? '${value.toStringAsFixed(0)}%' : '',
                  color: colors[index % colors.length],
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRadarChart(ThemeData theme) {
    final categoryData = _categoryBreakdown;
    final categories = categoryData.entries.take(6).toList();

    if (categories.isEmpty) {
      return const Center(child: Text('Pas de données disponibles'));
    }

    final maxVal = categories.fold<double>(
        0, (max, e) => e.value > max ? e.value.toDouble() : max);

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: categories.map((entry) {
              return RadarEntry(
                  value: maxVal > 0 ? entry.value / maxVal : 0);
            }).toList(),
            fillColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            borderColor: theme.colorScheme.primary,
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        radarShape: RadarShape.circle,
        getTitle: (index, angle) {
          if (index >= 0 && index < categories.length) {
            return RadarChartTitle(
                text: categories[index].key.displayName, angle: angle);
          }
          return const RadarChartTitle(text: '');
        },
        titleTextStyle: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurface,
        ),
        tickCount: 3,
        gridBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        tickBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme) {
    final categoryData = _categoryBreakdown;

    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalCompletions =
        categoryData.values.fold<int>(0, (sum, v) => sum + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Répartition par catégorie',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...categoryData.entries.map((entry) {
              final percentage = totalCompletions > 0
                  ? (entry.value / totalCompletions * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(entry.key.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(entry.key.displayName),
                          ],
                        ),
                        Text(
                            '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    final recentEntries = <MapEntry<String, DateTime>>[];

    for (final habit in _filteredHabits) {
      for (final entry in habit.entries.where((e) => e.count > 0)) {
        recentEntries.add(MapEntry(habit.name, entry.date));
      }
    }

    recentEntries.sort((a, b) => b.value.compareTo(a.value));
    final recent = recentEntries.take(10).toList();

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activité récente',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...recent.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(entry.value.day.toString(),
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer)),
                  ),
                  title: Text(entry.key),
                  subtitle: Text(
                      '${entry.value.day}/${entry.value.month}/${entry.value.year}'),
                  trailing:
                      const Icon(Icons.check_circle, color: Colors.green),
                )),
          ],
        ),
      ),
    );
  }
}
