import 'package:flutter/material.dart';
import 'package:ascend/data/models/challenge.dart';
import 'package:ascend/core/services/challenge_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  Challenge get challenge => widget.challenge;

  void _refresh() => setState(() {});

  Color _difficultyColor() {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.extreme:
        return Colors.deepPurple;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  // --- Actions ---
  Future<void> _deleteChallenge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le défi'),
        content: Text(
            'Voulez-vous vraiment supprimer « ${challenge.name} » ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ChallengeService.deleteChallenge(challenge.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _startChallenge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Commencer le défi'),
        content: const Text('Voulez-vous commencer ce défi maintenant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ChallengeService.startChallenge(challenge.id);
      _refresh();
    }
  }

  Future<void> _toggleTodayCompleted() async {
    final alreadyDone = ChallengeService.isCompletedToday(challenge);
    if (alreadyDone) return;
    await ChallengeService.completeDay(challenge.id, DateTime.now());
    _refresh();
    if (challenge.daysCompleted >= challenge.durationDays) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Félicitations ! Vous avez terminé le défi !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _abandonChallenge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner le défi'),
        content: const Text('Voulez-vous vraiment abandonner ce défi ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, abandonner'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ChallengeService.failChallenge(challenge.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // --- UI Sections ---
  Widget _buildHeader() {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final isCompletedToday = challenge.completedDays.contains(todayStr);

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            if (challenge.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.durationDays} jours',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    challenge.difficulty.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _difficultyColor(),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 18, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.xpReward} XP',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber[700]),
                    ),
                  ],
                ),
                if (challenge.badgeName != null && challenge.badgeName!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.military_tech, size: 18, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        challenge.badgeName!,
                        style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(challenge.progression * 100).round()}%',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${challenge.daysCompleted} / ${challenge.durationDays} jours complétés',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: challenge.progression,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                color: challenge.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            if (challenge.isActive)
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.remainingDays} jours restants',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (isCompletedToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Fait aujourd\'hui', style: TextStyle(fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    ),
                ],
              ),
            if (challenge.isCompleted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Défi terminé !',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (!challenge.isActive && !challenge.isCompleted) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: challenge.progression,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      color: challenge.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${challenge.daysCompleted}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'sur ${challenge.durationDays}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLast7DaysCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLast7DaysCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7 derniers jours',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            final dateStr = day.toIso8601String().substring(0, 10);
            final isCompleted = challenge.completedDays.contains(dateStr);
            final isToday = i == 6;

            return Column(
              children: [
                Text(
                  labels[(day.weekday - 1) % 7],
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : isToday
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRewardSection() {
    if (challenge.rewardDescription == null || challenge.rewardDescription!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récompense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.08),
                    Colors.orange.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber[700], size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          challenge.rewardDescription!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.xpReward} XP à gagner',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (challenge.isCompleted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          if (challenge.status == ChallengeStatus.available)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startChallenge,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer le défi'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (challenge.isActive) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ChallengeService.isCompletedToday(challenge) ? null : _toggleTodayCompleted,
                icon: Icon(
                  ChallengeService.isCompletedToday(challenge)
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  ChallengeService.isCompletedToday(challenge)
                      ? 'Déjà fait aujourd\'hui'
                      : 'Marquer aujourd\'hui comme fait',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ChallengeService.isCompletedToday(challenge)
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.green,
                  foregroundColor: ChallengeService.isCompletedToday(challenge)
                      ? Colors.green[800]
                      : Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _abandonChallenge,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Abandonner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (!challenge.isActive && !challenge.isCompleted) return const SizedBox.shrink();

    final streak = _calculateCurrentStreak();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.local_fire_department,
                  '$streak',
                  'Série actuelle',
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.check_circle_outline,
                  '${challenge.daysCompleted}',
                  'Jours complétés',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.pie_chart_outline,
                  '${(challenge.progression * 100).round()}%',
                  'Progression',
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  int _calculateCurrentStreak() {
    if (challenge.completedDays.isEmpty) return 0;

    final sortedDays = challenge.completedDays.toList()..sort();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = today;

    for (var i = 0; i < 365; i++) {
      final dateStr = checkDate.toIso8601String().substring(0, 10);
      if (sortedDays.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: _deleteChallenge,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildProgressSection(),
            _buildRewardSection(),
            _buildStatsSection(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
