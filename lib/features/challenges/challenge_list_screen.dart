import 'package:flutter/material.dart';
import 'package:ascend/data/models/challenge.dart';
import 'package:ascend/core/services/challenge_service.dart';
import 'package:ascend/features/challenges/challenge_detail_screen.dart';
import 'package:ascend/features/challenges/create_challenge_sheet.dart';

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Challenge> _availableChallenges = [];
  List<Challenge> _activeChallenges = [];
  List<Challenge> _completedChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    await ChallengeService.loadChallenges();
    setState(() {
      _availableChallenges = ChallengeService.getAvailableChallenges();
      _activeChallenges = ChallengeService.getActiveChallenges();
      _completedChallenges = ChallengeService.getCompletedChallenges();
      _isLoading = false;
    });
  }

  void _showCreateChallengeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateChallengeSheet(
        onSave: (challenge) async {
          await ChallengeService.addChallenge(challenge);
          Navigator.pop(context);
          _loadChallenges();
        },
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.extreme:
        return Colors.purple;
    }
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return Colors.blue;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.completed:
        return Colors.teal;
      case ChallengeStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return Icons.inbox_outlined;
      case ChallengeStatus.active:
        return Icons.play_circle;
      case ChallengeStatus.completed:
        return Icons.check_circle;
      case ChallengeStatus.failed:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Défis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showCreateChallengeSheet,
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un défi',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChallengeSheet,
        tooltip: 'Nouveau défi',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChallengeList(_availableChallenges, ChallengeStatus.available),
                _buildChallengeList(_activeChallenges, ChallengeStatus.active),
                _buildChallengeList(_completedChallenges, ChallengeStatus.completed),
              ],
            ),
    );
  }

  Widget _buildChallengeList(List<Challenge> challenges, ChallengeStatus tabStatus) {
    if (challenges.isEmpty) {
      return _buildEmptyState(tabStatus);
    }
    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          return _buildChallengeCard(challenges[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(ChallengeStatus status) {
    String title;
    String message;
    IconData icon;

    switch (status) {
      case ChallengeStatus.available:
        title = 'Aucun défi disponible';
        message = 'Créez un nouveau défi pour commencer votre progression.';
        icon = Icons.emoji_events_outlined;
        break;
      case ChallengeStatus.active:
        title = 'Aucun défi en cours';
        message = 'Rejoignez un défi disponible pour relever le défi.';
        icon = Icons.play_circle_outline;
        break;
      case ChallengeStatus.completed:
        title = 'Aucun défi terminé';
        message = 'Terminez vos défis en cours pour les voir ici.';
        icon = Icons.check_circle_outline;
        break;
      case ChallengeStatus.failed:
        title = 'Aucun défi échoué';
        message = 'Vous n\'avez pas encore échoué à un défi.';
        icon = Icons.cancel_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateChallengeSheet,
            icon: const Icon(Icons.add),
            label: const Text('Créer un défi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final difficultyColor = _getDifficultyColor(challenge.difficulty);
    final statusColor = _getStatusColor(challenge.status);
    final statusIcon = _getStatusIcon(challenge.status);
    final progress = challenge.progression.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
          _loadChallenges();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                          challenge.status.displayName,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.durationDays} jours',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      challenge.difficulty.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: difficultyColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.xpReward} XP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              if (challenge.badgeName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      challenge.badgeName!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
              if (challenge.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progressPercent %',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${challenge.daysCompleted}/${challenge.durationDays} jours complétés',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
