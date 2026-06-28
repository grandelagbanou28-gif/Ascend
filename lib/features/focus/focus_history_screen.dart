import 'package:flutter/material.dart';
import 'package:ascend/data/models/focus_session.dart';
import 'package:ascend/core/services/focus_service.dart';

class FocusHistoryScreen extends StatefulWidget {
  const FocusHistoryScreen({super.key});

  @override
  State<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

enum _Filter { all, today, week, month }

class _FocusHistoryScreenState extends State<FocusHistoryScreen> {
  _Filter _selectedFilter = _Filter.all;
  List<FocusSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    await FocusService.loadSessions();
    setState(() {
      _sessions = _applyFilter(FocusService.sessions);
      _isLoading = false;
    });
  }

  List<FocusSession> _applyFilter(List<FocusSession> all) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case _Filter.all:
        return all;
      case _Filter.today:
        return all.where((s) {
          return s.startTime.year == now.year &&
              s.startTime.month == now.month &&
              s.startTime.day == now.day;
        }).toList();
      case _Filter.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return all.where((s) => s.startTime.isAfter(startOfWeek)).toList();
      case _Filter.month:
        return all.where((s) {
          return s.startTime.year == now.year && s.startTime.month == now.month;
        }).toList();
    }
  }

  void _onFilterChanged(_Filter filter) {
    setState(() {
      _selectedFilter = filter;
      _sessions = _applyFilter(FocusService.sessions);
    });
  }

  Future<void> _deleteSession(FocusSession session) async {
    await FocusService.deleteSession(session.id);
    setState(() {
      _sessions = _applyFilter(FocusService.sessions);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session supprimée')),
      );
    }
  }

  Color _getStatusColor(FocusSessionStatus status) {
    switch (status) {
      case FocusSessionStatus.running:
        return Colors.green;
      case FocusSessionStatus.paused:
        return Colors.orange;
      case FocusSessionStatus.completed:
        return Colors.blue;
      case FocusSessionStatus.interrupted:
        return Colors.red;
    }
  }

  String _getStatusLabel(FocusSessionStatus status) {
    switch (status) {
      case FocusSessionStatus.running:
        return 'En cours';
      case FocusSessionStatus.paused:
        return 'En pause';
      case FocusSessionStatus.completed:
        return 'Terminé';
      case FocusSessionStatus.interrupted:
        return 'Interrompu';
    }
  }

  IconData _getStatusIcon(FocusSessionStatus status) {
    switch (status) {
      case FocusSessionStatus.running:
        return Icons.play_circle;
      case FocusSessionStatus.paused:
        return Icons.pause_circle;
      case FocusSessionStatus.completed:
        return Icons.check_circle;
      case FocusSessionStatus.interrupted:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historique Focus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: _sessions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadSessions,
                          child: _buildSessionList(),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip('Toutes', _Filter.all),
          const SizedBox(width: 8),
          _buildChip("Aujourd'hui", _Filter.today),
          const SizedBox(width: 8),
          _buildChip('Cette semaine', _Filter.week),
          const SizedBox(width: 8),
          _buildChip('Ce mois', _Filter.month),
        ],
      ),
    );
  }

  Widget _buildChip(String label, _Filter filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(filter),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune session',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Commencez une session de focus pour la voir apparaître ici.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(FocusSession session) {
    final statusColor = _getStatusColor(session.status);
    final statusLabel = _getStatusLabel(session.status);
    final statusIcon = _getStatusIcon(session.status);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer la session ?'),
            content: const Text(
                'Cette action est irréversible. Voulez-vous continuer ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteSession(session),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${_formatDate(session.startTime)}  ${_formatTime(session.startTime)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.mode.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.actualMinutes} min',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (session.sound != AmbientSound.none) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${session.sound.icon} ${session.sound.displayName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.xpEarned} XP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
