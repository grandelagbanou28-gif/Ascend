import 'package:flutter/material.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/data/models/habit.dart';
import 'package:ascend/data/models/habit_entry.dart';
import 'package:ascend/core/services/storage_service.dart';
import 'package:intl/intl.dart';

enum CalendarViewMode { jour, semaine, mois, annee }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.mois;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<Habit> _habits = [];
  bool _loading = true;

  static const Color _colorSuccess = Color(0xFF4CAF50);
  static const Color _colorPartial = Color(0xFFFF9800);
  static const Color _colorFailed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _loading = true);
    final habits = await StorageService.loadAll();
    if (mounted) {
      setState(() {
        _habits = habits.where((h) => !h.isArchived).toList();
        _loading = false;
      });
    }
  }

  List<Habit> _getHabitsForDay(DateTime day) {
    return _habits.where((h) => _isHabitDueOnDay(h, day)).toList();
  }

  bool _isHabitDueOnDay(Habit habit, DateTime day) {
    if (habit.isPaused) return false;

    switch (habit.frequency) {
      case HabitFrequency.Daily:
        return true;
      case HabitFrequency.MondayOnly:
        return day.weekday == DateTime.monday;
      case HabitFrequency.Weekend:
        return day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday;
      case HabitFrequency.Every2Days:
        final daysSinceCreated = day.difference(habit.createdAt).inDays;
        return daysSinceCreated % 2 == 0;
      case HabitFrequency.Weekly:
        return day.weekday == habit.createdAt.weekday;
      case HabitFrequency.Monthly:
        return day.day == habit.createdAt.day;
      case HabitFrequency.CustomDays:
        final dayIndex = day.weekday % 7;
        return habit.customDays.contains(dayIndex);
    }
  }

  List<HabitEntry> _getEntriesForDay(Habit habit, DateTime day) {
    return habit.entries
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }

  Color _getDayColor(DateTime day) {
    final dueHabits = _getHabitsForDay(day);
    if (dueHabits.isEmpty) return Colors.transparent;

    int completedCount = 0;
    for (final habit in dueHabits) {
      final entries = _getEntriesForDay(habit, day);
      if (entries.any((e) => e.count > 0)) {
        completedCount++;
      }
    }

    if (completedCount == dueHabits.length) return _colorSuccess;
    if (completedCount > 0) return _colorPartial;
    return _colorFailed;
  }

  bool _hasDataForDay(DateTime day) {
    final dueHabits = _getHabitsForDay(day);
    if (dueHabits.isEmpty) return false;
    for (final habit in dueHabits) {
      if (_getEntriesForDay(habit, day).isNotEmpty) return true;
    }
    return false;
  }

  void _navigateDate(int delta) {
    setState(() {
      switch (_viewMode) {
        case CalendarViewMode.jour:
          _selectedDate = _selectedDate.add(Duration(days: delta));
          break;
        case CalendarViewMode.semaine:
          _selectedDate = _selectedDate.add(Duration(days: delta * 7));
          break;
        case CalendarViewMode.mois:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + delta,
            1,
          );
          break;
        case CalendarViewMode.annee:
          _selectedDate = DateTime(
            _selectedDate.year + delta,
            _selectedDate.month,
            1,
          );
          break;
      }
    });
  }

  String _getTitle() {
    switch (_viewMode) {
      case CalendarViewMode.jour:
        return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate);
      case CalendarViewMode.semaine:
        final start = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'fr_FR').format(start)} - ${DateFormat('d MMM yyyy', 'fr_FR').format(end)}';
      case CalendarViewMode.mois:
        return DateFormat('MMMM yyyy', 'fr_FR').format(_selectedDate);
      case CalendarViewMode.annee:
        return '${_selectedDate.year}';
    }
  }

  void _showDayDetails(DateTime day) {
    final dueHabits = _getHabitsForDay(day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DayDetailsSheet(
        day: day,
        habits: _habits,
        dueHabits: dueHabits,
        getEntriesForDay: _getEntriesForDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildLegend(theme),
                _buildViewSelector(theme),
                _buildDateNavigator(theme),
                Expanded(child: _buildCurrentView(theme)),
              ],
            ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(_colorSuccess, 'Réussi', theme),
          const SizedBox(width: 20),
          _legendItem(_colorPartial, 'Partiel', theme),
          const SizedBox(width: 20),
          _legendItem(_colorFailed, 'Raté', theme),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildViewSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<CalendarViewMode>(
        segments: const [
          ButtonSegment(
            value: CalendarViewMode.jour,
            label: Text('Jour'),
          ),
          ButtonSegment(
            value: CalendarViewMode.semaine,
            label: Text('Semaine'),
          ),
          ButtonSegment(
            value: CalendarViewMode.mois,
            label: Text('Mois'),
          ),
          ButtonSegment(
            value: CalendarViewMode.annee,
            label: Text('Année'),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (selected) {
          setState(() => _viewMode = selected.first);
        },
      ),
    );
  }

  Widget _buildDateNavigator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigateDate(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              _getTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => _navigateDate(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme) {
    switch (_viewMode) {
      case CalendarViewMode.jour:
        return _buildDayView(theme);
      case CalendarViewMode.semaine:
        return _buildWeekView(theme);
      case CalendarViewMode.mois:
        return _buildMonthView(theme);
      case CalendarViewMode.annee:
        return _buildYearView(theme);
    }
  }

  Widget _buildDayView(ThemeData theme) {
    final dueHabits = _getHabitsForDay(_selectedDate);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: dueHabits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune habitude prévue ce jour',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: dueHabits.length,
              itemBuilder: (context, index) {
                final habit = dueHabits[index];
                final entries = _getEntriesForDay(habit, _selectedDate);
                final isCompleted = entries.any((e) => e.count > 0);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? _colorSuccess.withValues(alpha: 0.2)
                          : entries.isNotEmpty
                              ? _colorFailed.withValues(alpha: 0.2)
                              : theme.colorScheme.outline.withValues(alpha: 0.1),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : entries.isNotEmpty
                                ? Icons.cancel
                                : Icons.help_outline,
                        color: isCompleted
                            ? _colorSuccess
                            : entries.isNotEmpty
                                ? _colorFailed
                                : theme.colorScheme.outline,
                      ),
                    ),
                    title: Text(
                      habit.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      isCompleted
                          ? 'Réussi'
                          : entries.isNotEmpty
                              ? 'Raté'
                              : 'Pas encore complété',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCompleted
                            ? _colorSuccess
                            : entries.isNotEmpty
                                ? _colorFailed
                                : theme.colorScheme.outline,
                      ),
                    ),
                    trailing: habit.targetValue != null
                        ? Text(
                            habit.targetUnit ?? '',
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildWeekView(ThemeData theme) {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final days = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .asMap()
                .entries
                .map(
                  (entry) => Expanded(
                    child: Center(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 1,
              childAspectRatio: 3,
              children: days.map((day) {
                final isToday = _isSameDay(day, DateTime.now());
                final isSelected = _isSameDay(day, _selectedDate);
                final color = _getDayColor(day);
                final hasData = _hasDataForDay(day);

                return GestureDetector(
                  onTap: () => _showDayDetails(day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                : color.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        if (hasData) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(ThemeData theme) {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    final blankDays = startWeekday - 1;
    final totalCells = blankDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: rows * 7,
              itemBuilder: (context, index) {
                final dayOffset = index - blankDays + 1;
                if (dayOffset < 1 || dayOffset > daysInMonth) {
                  return const SizedBox();
                }

                final day = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  dayOffset,
                );
                final isToday = _isSameDay(day, DateTime.now());
                final isSelected = _isSameDay(day, _selectedDate);
                final color = _getDayColor(day);

                return GestureDetector(
                  onTap: () => _showDayDetails(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayOffset',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isToday || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          if (color != Colors.transparent)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearView(ThemeData theme) {
    final months = List.generate(12, (i) => DateTime(_selectedDate.year, i + 1, 1));
    final monthNames = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = months[index];
          final isCurrentMonth = month.month == DateTime.now().month &&
              month.year == DateTime.now().year;
          final isSelectedMonth = month.month == _selectedDate.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, month.month, 1);
                _viewMode = CalendarViewMode.mois;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelectedMonth
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentMonth
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: isCurrentMonth ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    monthNames[index],
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelectedMonth
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildMiniMonthGrid(theme, month),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniMonthGrid(ThemeData theme, DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;
    final blankDays = startWeekday - 1;

    return Column(
      children: List.generate(5, (weekIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (dayIndex) {
            final cellIndex = weekIndex * 7 + dayIndex - blankDays + 1;
            if (cellIndex < 1 || cellIndex > daysInMonth) {
              return const SizedBox(width: 8, height: 8);
            }

            final day = DateTime(month.year, month.month, cellIndex);
            final color = _getDayColor(day);

            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color == Colors.transparent
                    ? theme.colorScheme.outline.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayDetailsSheet extends StatelessWidget {
  final DateTime day;
  final List<Habit> habits;
  final List<Habit> dueHabits;
  final List<HabitEntry> Function(Habit, DateTime) getEntriesForDay;

  const _DayDetailsSheet({
    required this.day,
    required this.habits,
    required this.dueHabits,
    required this.getEntriesForDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dueHabits.length} habitude${dueHabits.length > 1 ? 's' : ''} prévue${dueHabits.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              if (dueHabits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aucune habitude prévue pour ce jour',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                )
              else
                ...dueHabits.map((habit) {
                  final entries = getEntriesForDay(habit, day);
                  final isCompleted = entries.any((e) => e.count > 0);
                  final isPartial = entries.isNotEmpty && !isCompleted;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompleted
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                            : isPartial
                                ? const Color(0xFFF44336).withValues(alpha: 0.2)
                                : theme.colorScheme.outline.withValues(alpha: 0.1),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isPartial
                                  ? Icons.cancel
                                  : Icons.help_outline,
                          color: isCompleted
                              ? const Color(0xFF4CAF50)
                              : isPartial
                                  ? const Color(0xFFF44336)
                                  : theme.colorScheme.outline,
                        ),
                      ),
                      title: Text(
                        habit.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        isCompleted
                            ? 'Réussi'
                            : isPartial
                                ? 'Raté'
                                : 'Pas encore complété',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCompleted
                              ? const Color(0xFF4CAF50)
                              : isPartial
                                  ? const Color(0xFFF44336)
                                  : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
