import 'package:flutter/material.dart';
import 'package:ascend/core/services/gamification_service.dart' as gamification;

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildBadgesSection(context),
            const SizedBox(height: 24),
            _buildTitlesSection(context),
            const SizedBox(height: 24),
            _buildQuickStats(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final xp = gamification.GamificationService.xp;
    final level = gamification.GamificationService.level;
    final coins = gamification.GamificationService.coins;
    final title = gamification.GamificationService.title;
    final progress = gamification.GamificationService.levelProgress;
    final xpForNext = gamification.GamificationService.xpForNextLevel;
    final xpProgress = gamification.GamificationService.xpProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Niveau $level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$xpProgress / $xpForNext XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$coins pièces',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
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

  Widget _buildBadgesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badges = gamification.Badge.all;
    final unlockedBadges = gamification.GamificationService.unlockedBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final isUnlocked = unlockedBadges.contains(badge.id);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge.icon,
                      style: TextStyle(
                        fontSize: 32,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isUnlocked
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTitlesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titles = gamification.GamificationService.titles;
    final currentTitle = gamification.GamificationService.title;
    final level = gamification.GamificationService.level;

    final titleRequirements = {
      'Débutant': 0,
      'Novice': 10,
      'Discipliné': 20,
      'Expert': 30,
      'Maître': 40,
      'Légende': 50,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Titres',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...titles.map((title) {
          final requiredLevel = titleRequirements[title] ?? 0;
          final isUnlocked = level >= requiredLevel;
          final isCurrent = title == currentTitle;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: isUnlocked
                      ? Icon(
                          Icons.check,
                          color: colorScheme.primary,
                        )
                      : Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isUnlocked
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              subtitle: Text(
                'Niveau $requiredLevel requis',
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              trailing: isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Actif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final xp = gamification.GamificationService.xp;
    final level = gamification.GamificationService.level;
    final coins = gamification.GamificationService.coins;
    final unlockedCount = gamification.GamificationService.unlockedBadges.length;
    final totalBadges = gamification.Badge.all.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.star,
                label: 'XP total',
                value: '$xp',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.leaderboard,
                label: 'Niveau',
                value: '$level',
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.emoji_events,
                label: 'Badges',
                value: '$unlockedCount / $totalBadges',
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.monetization_on,
                label: 'Pièces',
                value: '$coins',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
