// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ascend/features/habits/add_habit_sheet.dart';
import 'package:ascend/main.dart';
import 'package:ascend/features/settings/settings_screen.dart';
import 'package:ascend/features/analytics/analytics_dashboard.dart';
import 'package:ascend/core/services/reports_service.dart';
import 'package:ascend/data/models/habit.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/features/habits/habit_detail_screen.dart';
import 'package:ascend/data/models/habit_entry.dart';
import 'package:ascend/core/services/storage_service.dart';
import 'package:ascend/core/services/auth_service.dart';
import 'package:ascend/core/services/profile_service.dart';
import 'package:ascend/data/models/user_profile.dart';
import 'package:ascend/core/services/settings_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ascend/features/habits/bulk_edit_screen.dart';
import 'package:ascend/core/services/widget_service.dart';
import 'package:ascend/features/achievements/achievements_view.dart';
import 'package:ascend/features/backup_and_import/backup_import_screen.dart';
import 'package:ascend/features/gamification/points_screen.dart';
import 'package:ascend/core/services/keyboard_service.dart';
import 'package:ascend/core/widgets/keyboard_aware_widget.dart';
import 'package:ascend/core/widgets/focusable_button.dart';
import 'package:ascend/core/widgets/keyboard_shortcuts_dialog.dart';
import 'package:ascend/features/auth/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final Function(String)? changeTheme;
  
  const HomeScreen({super.key, 
    required this.toggleTheme, 
    required this.isDarkMode,
    this.changeTheme,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Habit> _habits = [];
  List<Habit> _activeHabits = [];
  List<Habit> _archivedHabits = [];
  List<Habit> _filteredHabits = [];
  late TabController _tabController;
  bool _isLoading = true;
  int _totalPositiveDays = 0;
  int _totalNegativeDays = 0;
  double _overallSuccessRate = 0;
  int _totalEntries = 0;
  int _bestCurrentStreak = 0;
  String _bestStreakHabit = '';
  bool _showArchived = false;
  HabitCategory? _selectedCategory;
  List<HabitCategory> _categories = [];
  
  // Dashboard state
  UserProfile? _profile;
  int _todayCompleted = 0;
  int _todayRemaining = 0;
  double _todayProgress = 0;
  int _todayFocusTime = 0;
  int _todayXpEarned = 0;
  
  // Widget visibility settings
  bool _showQuoteWidget = true;
  bool _showCalendarWidget = true;
  bool _showProgressionWidget = true;
  bool _showChallengesWidget = true;
  bool _showFocusWidget = true;
  bool _showGoalsWidget = true;
  bool _showJournalWidget = true;
  
  // Keyboard navigation
  late ScrollController _habitsScrollController;
  late ScrollController _dashboardScrollController;
  List<FocusNode> _focusableNodes = [];
  final KeyboardService _keyboardService = KeyboardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize scroll controllers
    _habitsScrollController = ScrollController();
    _dashboardScrollController = ScrollController();
    
    // Initialize focus nodes for keyboard navigation
    _initializeFocusNodes();
    
    // Add listener to update scroll controller when tab changes
    _tabController.addListener(_onTabChanged);
    
    _loadHabits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _habitsScrollController.dispose();
    _dashboardScrollController.dispose();
    
    // Dispose focus nodes
    for (var node in _focusableNodes) {
      node.dispose();
    }
    _focusableNodes.clear();
    
    super.dispose();
  }

  void _initializeFocusNodes() {
    // Create focus nodes for all interactive elements
    _focusableNodes = List.generate(20, (index) => FocusNode());
  }

  void _onTabChanged() {
    // Update the keyboard service with the current scroll controller
    if (_tabController.indexIsChanging) {
      final currentController = _tabController.index == 0 
          ? _habitsScrollController 
          : _dashboardScrollController;
      _keyboardService.setScrollController(currentController);
    }
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    
    // Load profile
    _profile = await ProfileService.getCurrentProfile();
    
    // Load widget settings
    await _loadWidgetSettings();
    
    final all = await StorageService.loadAll();
    
    // Filter active and archived habits
    final active = all.where((h) => !h.isArchived).toList();
    final archived = all.where((h) => h.isArchived).toList();
    
    // Extract categories
    final categories = active
        .map((h) => h.category)
        .toSet()
        .toList()
      ..sort();
    
    // Apply category filter
    final filtered = _selectedCategory == null 
        ? active 
        : active.where((h) => h.category == _selectedCategory).toList();
    
    // Calculate overall metrics (using filtered habits)
    int totalPositive = 0;
    int totalNegative = 0;
    int totalEntries = 0;
    int bestStreak = 0;
    String bestStreakHabit = '';
    
    for (var habit in filtered) {
      totalPositive += habit.entries.where((e) => e.count > 0).length;
      totalNegative += habit.entries.where((e) => e.count <= 0).length;
      totalEntries += habit.entries.length;
      
      if (habit.currentStreak > bestStreak) {
        bestStreak = habit.currentStreak;
        bestStreakHabit = habit.formattedName;
      }
    }
    
    // Calculate today's stats
    final today = DateTime.now();
    int todayCompleted = 0;
    int todayRemaining = 0;
    int todayFocusTime = 0;
    int todayXp = 0;
    
    for (var habit in active) {
      if (habit.isDueToday()) {
        final todayEntry = habit.entries.where((e) => 
          e.date.year == today.year && 
          e.date.month == today.month && 
          e.date.day == today.day
        ).firstOrNull;
        
        if (todayEntry != null) {
          todayCompleted++;
          todayXp += 10; // 10 XP per habit completed
        } else {
          todayRemaining++;
        }
      }
    }
    
    double todayProgress = (todayCompleted + todayRemaining) > 0 
        ? todayCompleted / (todayCompleted + todayRemaining) 
        : 0;
    
    setState(() {
      _habits = all;
      _activeHabits = active;
      _archivedHabits = archived;
      _filteredHabits = filtered;
      _categories = categories;
      _totalPositiveDays = totalPositive;
      _totalNegativeDays = totalNegative;
      _totalEntries = totalEntries;
      
      int totalDays = totalPositive + totalNegative;
      _overallSuccessRate = totalDays > 0 ? (totalPositive / totalDays) * 100 : 0;
      
      _bestCurrentStreak = bestStreak;
      _bestStreakHabit = bestStreakHabit;
      
      _todayCompleted = todayCompleted;
      _todayRemaining = todayRemaining;
      _todayProgress = todayProgress;
      _todayFocusTime = todayFocusTime;
      _todayXpEarned = todayXp;
      
      _isLoading = false;
    });
    
    // Update home widgets
    await WidgetService.updateHomeWidgets();
  }
  
  Future<void> _loadWidgetSettings() async {
    _showQuoteWidget = await SettingsService.getMotivationalQuotes();
    _showCalendarWidget = true; // Default
    _showProgressionWidget = true; // Default
    _showChallengesWidget = true; // Default
    _showFocusWidget = true; // Default
    _showGoalsWidget = true; // Default
    _showJournalWidget = true; // Default
  }

  void _showAddHabit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(
        onSave: (h) async {
          if (h.name.isEmpty) return;
          await StorageService.save(h);
          Navigator.pop(context);
          _loadHabits();
        }
      ),
    );
  }
  
  void _openSettings() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => SettingsScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ))
    ).then((_) => _loadHabits());
  }
  
  void _toggleArchiveView() {
    setState(() {
      _showArchived = !_showArchived;
    });
  }
  
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All Categories'),
              leading: Radio<HabitCategory?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadHabits();
                  Navigator.pop(context);
                },
              ),
            ),
            ..._categories.map((category) => ListTile(
              title: Text(category.displayName),
              leading: Radio<HabitCategory?>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadHabits();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDashboard(habits: _filteredHabits),
      ),
    );
  }

  void _openBackupScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupImportScreen(),
      ),
    );
  }

  void _openPointsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointsScreen(),
      ),
    );
  }

  void _showYearInReview() {
    final currentYear = DateTime.now().year;
    final yearReview = ReportsService.generateYearInReview(_filteredHabits, currentYear);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$currentYear Year in Review'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (yearReview.totalHabits == 0) ...[
                Text('No data available for $currentYear'),
                SizedBox(height: 16),
                Text('Start tracking habits to see your year in review!'),
              ] else ...[
                Text('🎯 Total Habits: ${yearReview.totalHabits}'),
                Text('📅 Total Entries: ${yearReview.totalEntries}'),
                Text('📊 Success Rate: ${yearReview.overallSuccessRate.toStringAsFixed(1)}%'),
                Text('🔥 Longest Streak: ${yearReview.longestStreak} days'),
                SizedBox(height: 16),
                if (yearReview.milestones.isNotEmpty) ...[
                  Text('🏆 Key Milestones:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...yearReview.milestones.take(3).map((milestone) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${milestone.title}'),
                  )),
                ],
                if (yearReview.insights.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('💡 Insights:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...yearReview.insights.take(3).map((insight) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${insight.title}: ${insight.description}'),
                  )),
                ],
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

  void _openBulkEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkEditScreen(habits: _habits),
      ),
    ).then((_) => _loadHabits());
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementsView(),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(),
      ),
    );
  }

  void _showKeyboardShortcuts() {
    showKeyboardShortcutsDialog(context);
  }

  void _handleClose() {
    // Close any open dialogs or navigate back
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _handleToggleFullscreen() {
    // This would need to be implemented based on the platform
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fullscreen toggle not implemented on this platform')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareWidget(
      scrollController: _tabController.index == 0 ? _habitsScrollController : _dashboardScrollController,
      onPreviousPage: () {
        if (_tabController.index > 0) {
          _tabController.animateTo(_tabController.index - 1);
        }
      },
      onNextPage: () {
        if (_tabController.index < _tabController.length - 1) {
          _tabController.animateTo(_tabController.index + 1);
        }
      },
      onClose: _handleClose,
      onToggleFullscreen: _handleToggleFullscreen,
      onAddHabit: _showAddHabit,
      onOpenSettings: _openSettings,
      onOpenAnalytics: _openAnalytics,
      onToggleArchive: _toggleArchiveView,
      onFilterByCategory: _showCategoryFilter,
      onBulkEdit: _openBulkEdit,
      onBackup: _openBackupScreen,
      onYearReview: _showYearInReview,
      onAchievements: _openAchievements,
      onPoints: _openPointsScreen,
      onShowKeyboardShortcuts: _showKeyboardShortcuts,
      focusableNodes: _focusableNodes,
      child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_showArchived ? 'Archived Habits' : 'Ascend', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            if (!_showArchived && _selectedCategory != null)
              Text(
                'Category: ${_selectedCategory!.displayName}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (!_showArchived && _categories.isNotEmpty)
            FocusableIconButton(
              icon: Icon(_selectedCategory != null ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: _showCategoryFilter,
              tooltip: 'Filter by Category (F)',
              focusNode: _focusableNodes.length > 2 ? _focusableNodes[2] : null,
            ),
          if (!_showArchived)
            FocusableIconButton(
              icon: Icon(Icons.analytics),
              onPressed: _openAnalytics,
              tooltip: 'Analytics Dashboard (D)',
              focusNode: _focusableNodes.length > 3 ? _focusableNodes[3] : null,
            ),
          if (!_showArchived && _filteredHabits.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'bulk_edit':
                    _openBulkEdit();
                    break;
                  case 'points':
                    _openPointsScreen();
                    break;
                  case 'backup':
                    _openBackupScreen();
                    break;
                  case 'year_review':
                    _showYearInReview();
                    break;
                  case 'achievements':
                    _openAchievements();
                    break;
                  case 'profile':
                    _openProfile();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'bulk_edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, size: 18),
                      SizedBox(width: 8),
                      Text('Bulk Edit'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'points',
                  child: Row(
                    children: [
                      Icon(Icons.stars, size: 18),
                      SizedBox(width: 8),
                      Text('Points & Rewards'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'backup',
                  child: Row(
                    children: [
                      Icon(Icons.backup, size: 18),
                      SizedBox(width: 8),
                      Text('Backup & Import'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'year_review',
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text('Year in Review'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'achievements',
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 18),
                      SizedBox(width: 8),
                      Text('Achievements'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Mon profil'),
                    ],
                  ),
                ),
              ],
            ),
          FocusableIconButton(
            icon: Icon(_showArchived ? Icons.inventory_2_outlined : Icons.archive),
            onPressed: _toggleArchiveView,
            tooltip: _showArchived ? 'Show Active Habits' : 'Show Archived',
            focusNode: _focusableNodes.length > 4 ? _focusableNodes[4] : null,
          ),
          FocusableIconButton(
            icon: Icon(Icons.keyboard),
            onPressed: _showKeyboardShortcuts,
            tooltip: 'Keyboard Shortcuts (F1)',
            focusNode: _focusableNodes.isNotEmpty ? _focusableNodes[0] : null,
          ),
          FocusableIconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings (S)',
            focusNode: _focusableNodes.length > 1 ? _focusableNodes[1] : null,
          ),
        ],
        bottom: !_showArchived ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Habits'),
            Tab(text: 'Dashboard'),
          ],
        ) : null,
      ),
      floatingActionButton: !_showArchived ? FocusableButton(
        onPressed: _showAddHabit,
        focusNode: _focusableNodes.length > 5 ? _focusableNodes[5] : null,
        child: Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _showArchived 
              ? _buildArchivedList()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _filteredHabits.isEmpty ? _buildEmpty() : _buildHabitsList(_filteredHabits),
                    _buildDashboard(),
                  ],
                ),
      ),
    );
  }

  Widget _buildArchivedList() {
    if (_archivedHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No archived habits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Archived habits will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            TextButton.icon(
              onPressed: _toggleArchiveView,
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Active Habits'),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      controller: _habitsScrollController,
      padding: EdgeInsets.all(16),
      itemCount: _archivedHabits.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (_, i) {
        final habit = _archivedHabits[i];
        return HabitListItem(
          habit: habit,
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))
            );
            _loadHabits();
          },
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_circle_outline, size: 72, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No habits yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          'Start tracking your habits to build better routines',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAddHabit,
          icon: Icon(Icons.add),
          label: Text('Create Habit'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    ),
  );

  Widget _buildHabitsList(List<Habit> habits) {
    return ListView.separated(
      controller: _habitsScrollController,
      padding: EdgeInsets.all(16),
      itemCount: habits.length, // Add 1 for QuickEntryWidget
      separatorBuilder: (context, index) {
        if (index == 0) return SizedBox(height: 16); // Space after quick entry
        return SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        // if (index == 0) {
        //   // Quick entry widget at the top
        //   return QuickEntryWidget(
        //     habits: _habits,
        //     onUpdate: _loadHabits,
        //   );
        // }
        
        final habit = habits[index];
        return HabitListItem(
          habit: habit,
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))
            );
            _loadHabits();
          },
        );
      },
    );
  }
  
  Widget _buildDashboard() {
    return SingleChildScrollView(
      controller: _dashboardScrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main greeting card
          _buildGreetingCard(),
          SizedBox(height: 16),
          
          // Today's stats
          _buildTodayStats(),
          SizedBox(height: 16),
          
          // Progress bar
          _buildProgressBar(),
          SizedBox(height: 16),
          
          // Summary
          _buildSummary(),
          SizedBox(height: 16),
          
          // Customizable widgets
          if (_showQuoteWidget) ...[
            _buildQuoteWidget(),
            SizedBox(height: 16),
          ],
          if (_showCalendarWidget) ...[
            _buildCalendarWidget(),
            SizedBox(height: 16),
          ],
          if (_showProgressionWidget) ...[
            _buildProgressionWidget(),
            SizedBox(height: 16),
          ],
          if (_showChallengesWidget) ...[
            _buildChallengesWidget(),
            SizedBox(height: 16),
          ],
          if (_showFocusWidget) ...[
            _buildFocusWidget(),
            SizedBox(height: 16),
          ],
          if (_showGoalsWidget) ...[
            _buildGoalsWidget(),
            SizedBox(height: 16),
          ],
          if (_showJournalWidget) ...[
            _buildJournalWidget(),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    String greeting = 'Bonjour';
    if (hour >= 12 && hour < 18) {
      greeting = 'Bon après-midi';
    } else if (hour >= 18) {
      greeting = 'Bonsoir';
    }
    
    final userName = _profile?.displayName ?? AuthService.userDisplayName ?? 'Utilisateur';
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.local_fire_department,
                  label: 'Série',
                  value: '${_profile?.currentStreak ?? _bestCurrentStreak} j',
                ),
                SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.star,
                  label: 'Niveau',
                  value: '${_profile?.level ?? 1}',
                ),
                SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.bolt,
                  label: 'XP',
                  value: '${_profile?.xp ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayStats() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aujourd\'hui',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTodayStatItem(
                    icon: Icons.pending_actions,
                    label: 'Restantes',
                    value: '$_todayRemaining',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildTodayStatItem(
                    icon: Icons.check_circle,
                    label: 'Terminées',
                    value: '$_todayCompleted',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildTodayStatItem(
                    icon: Icons.timer,
                    label: 'Focus',
                    value: _formatTime(_todayFocusTime),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildTodayStatItem(
                    icon: Icons.bolt,
                    label: 'XP',
                    value: '+$_todayXpEarned',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTodayStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar() {
    final percentage = (_todayProgress * 100).toInt();
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$percentage %',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _todayProgress,
                minHeight: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _todayProgress >= 1.0
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '$_todayCompleted sur ${_todayCompleted + _todayRemaining} habitudes terminées',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSummaryRow(
              icon: Icons.calendar_today,
              label: 'Aujourd\'hui',
              value: '${_todayCompleted + _todayRemaining} habitudes',
            ),
            Divider(),
            _buildSummaryRow(
              icon: Icons.check_circle,
              label: 'Terminées',
              value: '$_todayCompleted',
            ),
            Divider(),
            _buildSummaryRow(
              icon: Icons.pending_actions,
              label: 'Restantes',
              value: '$_todayRemaining',
            ),
            Divider(),
            _buildSummaryRow(
              icon: Icons.timer,
              label: 'Temps Focus',
              value: _formatTime(_todayFocusTime),
            ),
            Divider(),
            _buildSummaryRow(
              icon: Icons.bolt,
              label: 'XP gagné',
              value: '+$_todayXpEarned',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuoteWidget() {
    final quotes = [
      'La régularité est la clé du succès.',
      'Chaque jour est une nouvelle chance de s\'améliorer.',
      'Les petites actions mènent à de grands résultats.',
      'La persévérance vient à bout de tout.',
      'Croyez en vous et tout est possible.',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Citation du jour',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '"$quote"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalendarWidget() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Calendrier',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              DateFormat('MMMM yyyy', 'fr').format(now),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            // Simple calendar grid
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(daysInMonth, (index) {
                final day = index + 1;
                final isToday = day == now.day;
                final isPast = day < now.day;
                
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : isPast
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isToday ? Colors.white : null,
                        fontWeight: isToday ? FontWeight.bold : null,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressionWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()], style: TextStyle(fontSize: 12));
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final value = (index < 5) ? (60.0 + index * 8) : (20.0 + index * 5);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
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
  
  Widget _buildChallengesWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Défis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildChallengeItem(
              title: '7 jours consécutifs',
              progress: (_profile?.currentStreak ?? 0) / 7,
              reward: '+50 XP',
            ),
            SizedBox(height: 8),
            _buildChallengeItem(
              title: '10 habitudes créées',
              progress: _activeHabits.length / 10,
              reward: '+100 XP',
            ),
            SizedBox(height: 8),
            _buildChallengeItem(
              title: '50 entrées complétées',
              progress: _totalEntries / 50,
              reward: '+200 XP',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChallengeItem({
    required String title,
    required double progress,
    required String reward,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            reward,
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFocusWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Focus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    _formatTime(_todayFocusTime),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Temps total aujourd\'hui',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  
  Widget _buildGoalsWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Objectifs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildGoalItem(
              title: 'Niveau ${(_profile?.level ?? 1) + 1}',
              progress: _profile?.xpProgress ?? 0,
              label: '${_profile?.xp ?? 0} / ${_profile?.xpForNextLevel ?? 100} XP',
            ),
            SizedBox(height: 8),
            _buildGoalItem(
              title: 'Série de ${(_profile?.currentStreak ?? 0) + 7} jours',
              progress: (_profile?.currentStreak ?? 0) / ((_profile?.currentStreak ?? 0) + 7),
              label: '${_profile?.currentStreak ?? 0} / ${(_profile?.currentStreak ?? 0) + 7} jours',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalItem({
    required String title,
    required double progress,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildJournalWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Journal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _profile?.favoriteQuote ?? 'Ajoutez une citation motivationnelle dans votre profil.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Open journal screen
              },
              icon: Icon(Icons.edit),
              label: Text('Écrire dans le journal'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m';
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    return '${hours}h ${minutes}m';
  }
}