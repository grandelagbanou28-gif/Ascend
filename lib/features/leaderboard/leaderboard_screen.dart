import 'package:flutter/material.dart';

class _LeaderboardUser {
  final String name;
  final String city;
  final String avatarUrl;
  final int score;
  final bool isCurrentUser;

  const _LeaderboardUser({
    required this.name,
    required this.city,
    required this.avatarUrl,
    required this.score,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'XP';

  final List<String> _filters = ['XP', 'Streak', 'Défis', 'Focus'];

  static const List<_LeaderboardUser> _mockUsers = [
    _LeaderboardUser(
      name: 'Émilie Laurent',
      city: 'Paris',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      score: 12450,
    ),
    _LeaderboardUser(
      name: 'Thomas Bernard',
      city: 'Lyon',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      score: 11200,
    ),
    _LeaderboardUser(
      name: 'Camille Dubois',
      city: 'Marseille',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      score: 10870,
    ),
    _LeaderboardUser(
      name: 'Lucas Moreau',
      city: 'Toulouse',
      avatarUrl: 'https://i.pravatar.cc/150?img=7',
      score: 9850,
    ),
    _LeaderboardUser(
      name: 'Chloé Petit',
      city: 'Nice',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      score: 9200,
    ),
    _LeaderboardUser(
      name: 'Antoine Roux',
      city: 'Nantes',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      score: 8740,
    ),
    _LeaderboardUser(
      name: 'Léa Fournier',
      city: 'Strasbourg',
      avatarUrl: 'https://i.pravatar.cc/150?img=13',
      score: 8100,
    ),
    _LeaderboardUser(
      name: 'Hugo Girard',
      city: 'Bordeaux',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      score: 7650,
    ),
    _LeaderboardUser(
      name: 'Manon Bonnet',
      city: 'Lille',
      avatarUrl: 'https://i.pravatar.cc/150?img=17',
      score: 7200,
    ),
    _LeaderboardUser(
      name: 'Nathan Leroy',
      city: 'Rennes',
      avatarUrl: 'https://i.pravatar.cc/150?img=19',
      score: 6890,
    ),
    _LeaderboardUser(
      name: 'Sophie Martin',
      city: 'Grenoble',
      avatarUrl: 'https://i.pravatar.cc/150?img=21',
      score: 6400,
    ),
    _LeaderboardUser(
      name: 'Maxime Fontaine',
      city: 'Dijon',
      avatarUrl: 'https://i.pravatar.cc/150?img=23',
      score: 5950,
    ),
    _LeaderboardUser(
      name: 'Jade Lefevre',
      city: 'Angers',
      avatarUrl: 'https://i.pravatar.cc/150?img=25',
      score: 5500,
    ),
    _LeaderboardUser(
      name: 'Romain Mercier',
      city: 'Clermont-Ferrand',
      avatarUrl: 'https://i.pravatar.cc/150?img=27',
      score: 5100,
    ),
    _LeaderboardUser(
      name: 'Clara Giroux',
      city: 'Tours',
      avatarUrl: 'https://i.pravatar.cc/150?img=29',
      score: 4750,
    ),
  ];

  static const _currentUser = _LeaderboardUser(
    name: 'Vous',
    city: 'Paris',
    avatarUrl: 'https://i.pravatar.cc/150?img=32',
    score: 6200,
    isCurrentUser: true,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getRankScore(_LeaderboardUser user) {
    switch (_selectedFilter) {
      case 'XP':
        return user.score;
      case 'Streak':
        return (user.score * 0.7).toInt();
      case 'Défis':
        return (user.score * 0.4).toInt();
      case 'Focus':
        return (user.score * 0.3).toInt();
      default:
        return user.score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sortedUsers = List<_LeaderboardUser>.from(_mockUsers)
      ..sort((a, b) => _getRankScore(b).compareTo(_getRankScore(a)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Mondial'),
            Tab(text: 'Amis'),
            Tab(text: 'Ville'),
            Tab(text: 'Pays'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      checkmarkColor: colorScheme.onPrimaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboard(context, sortedUsers),
                _buildLeaderboard(context, sortedUsers),
                _buildLeaderboard(context, sortedUsers),
                _buildLeaderboard(context, sortedUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(
      BuildContext context, List<_LeaderboardUser> sortedUsers) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final top3 = sortedUsers.take(3).toList();
    final remaining = sortedUsers.skip(3).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildPodium(context, top3),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Votre position',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildCurrentUserCard(context),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Classement complet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final rank = index + 4;
              return _buildUserRow(context, remaining[index], rank);
            },
            childCount: remaining.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildPodium(BuildContext context, List<_LeaderboardUser> top3) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (top3.length < 3) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPodiumSpot(context, top3[1], 2, 100, colorScheme.silver),
          const SizedBox(width: 8),
          _buildPodiumSpot(context, top3[0], 1, 130, colorScheme.gold),
          const SizedBox(width: 8),
          _buildPodiumSpot(context, top3[2], 3, 80, colorScheme.bronze),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(
    BuildContext context,
    _LeaderboardUser user,
    int rank,
    double height,
    Color medalColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -4,
                child: _getMedalIcon(rank, 28),
              ),
              CircleAvatar(
                radius: rank == 1 ? 32 : 26,
                backgroundColor: medalColor,
                child: CircleAvatar(
                  radius: rank == 1 ? 29 : 23,
                  backgroundImage: NetworkImage(user.avatarUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.name.split(' ').first,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatScore(_getRankScore(user)),
            style: theme.textTheme.labelMedium?.copyWith(
              color: medalColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: medalColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: medalColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: medalColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getMedalIcon(int rank, double size) {
    switch (rank) {
      case 1:
        return Icon(Icons.emoji_events, size: size, color: const Color(0xFFFFD700));
      case 2:
        return Icon(Icons.emoji_events, size: size, color: const Color(0xFFC0C0C0));
      case 3:
        return Icon(Icons.emoji_events, size: size, color: const Color(0xFFCD7F32));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCurrentUserCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentUserRank =
        _mockUsers.indexWhere((u) => u.name == _currentUser.name) + 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        color: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '$currentUserRank',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(_currentUser.avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      _currentUser.city,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatScore(_getRankScore(_currentUser)),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRow(
      BuildContext context, _LeaderboardUser user, int rank) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.city,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatScore(_getRankScore(user)),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 10000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return score.toString();
  }
}

extension _ColorExtensions on ColorScheme {
  Color get gold => const Color(0xFFFFD700);
  Color get silver => const Color(0xFFC0C0C0);
  Color get bronze => const Color(0xFFCD7F32);
}
