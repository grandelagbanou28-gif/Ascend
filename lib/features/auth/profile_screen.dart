import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ascend/core/services/auth_service.dart';
import 'package:ascend/core/services/profile_service.dart';
import 'package:ascend/data/models/user_profile.dart';
import 'package:ascend/features/auth/login_screen.dart';
import 'package:ascend/features/auth/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      _profile = await ProfileService.getCurrentProfile();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Changer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AuthService.reAuthenticate(
          email: AuthService.userEmail ?? '',
          password: currentPasswordController.text,
        );
        await AuthService.updatePassword(newPasswordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mot de passe mis à jour'), backgroundColor: Colors.green),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette action est irréversible.', style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe pour confirmer',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AuthService.reAuthenticate(
          email: AuthService.userEmail ?? '',
          password: passwordController.text,
        );
        await ProfileService.deleteProfile();
        await AuthService.deleteAccount();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    passwordController.dispose();
  }

  Future<void> _signOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Se déconnecter')),
        ],
      ),
    );

    if (result == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final profile = _profile;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(profile, user),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfileScreen(profile: profile)),
                        );
                        _loadProfile();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: _signOut,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCard(profile),
                        SizedBox(height: 16),
                        _buildInfoSection(profile, user),
                        SizedBox(height: 16),
                        _buildSecuritySection(user),
                        SizedBox(height: 16),
                        _buildDangerZone(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(UserProfile? profile, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                      ? Icon(Icons.person, size: 55, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getProviderIcon(AuthService.authProvider),
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              profile?.displayName ?? AuthService.userDisplayName ?? 'Utilisateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (profile?.username != null) ...[
              SizedBox(height: 4),
              Text(
                '@${profile!.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
            SizedBox(height: 4),
            Text(
              AuthService.userEmail ?? 'Anonyme',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Niveau ${profile?.level ?? 1} • ${profile?.levelTitle ?? "Novice"}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserProfile? profile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem(Icons.star, 'XP', '${profile?.xp ?? 0}')),
                Expanded(child: _buildStatItem(Icons.local_fire_department, 'Série', '${profile?.currentStreak ?? 0} j')),
                Expanded(child: _buildStatItem(Icons.emoji_events, 'Meilleure', '${profile?.bestStreak ?? 0} j')),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatItem(Icons.check_circle, 'Défis', '${profile?.challengesCompleted ?? 0}')),
                Expanded(child: _buildStatItem(Icons.timer, 'Focus', _formatTime(profile?.totalFocusTime ?? 0))),
                Expanded(child: _buildStatItem(Icons.star_border, 'Niveau', '${profile?.level ?? 1}')),
              ],
            ),
            SizedBox(height: 16),
            // XP Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progression XP', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '${profile?.xp ?? 0} / ${profile?.xpForNextLevel ?? 100}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: profile?.xpProgress ?? 0,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInfoSection(UserProfile? profile, dynamic user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoTile(Icons.person, 'Nom', profile?.displayName ?? '-'),
            _buildInfoTile(Icons.alternate_email, 'Pseudo', profile?.username ?? '-'),
            _buildInfoTile(Icons.flag, 'Pays', profile?.country ?? '-'),
            _buildInfoTile(Icons.language, 'Langue', profile?.language ?? '-'),
            _buildInfoTile(Icons.access_time, 'Fuseau horaire', profile?.timezone ?? '-'),
            _buildInfoTile(Icons.calendar_today, 'Inscrit le',
                DateFormat('dd/MM/yyyy').format(profile?.createdAt ?? DateTime.now())),
            _buildInfoTile(Icons.format_quote, 'Citation', profile?.favoriteQuote ?? '-'),
            if (user?.isAnonymous ?? false) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Compte invité. Liez un email pour sauvegarder vos données.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSecuritySection(dynamic user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sécurité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outlined),
              title: Text('Changer le mot de passe'),
              trailing: Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: _updatePassword,
            ),
            if (user?.isAnonymous ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.link),
                title: Text('Lier un email'),
                subtitle: Text('Pour sauvegarder votre compte'),
                trailing: Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  // TODO: Link email flow
                },
              ),
            if (!(user?.emailConfirmedAt != null))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.mark_email_outlined),
                title: Text('Vérifier l\'email'),
                trailing: Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () async {
                  try {
                    await AuthService.sendEmailVerification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Email de vérification envoyé'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zone dangereuse',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Supprimer le compte', style: TextStyle(color: Colors.red)),
              subtitle: Text('Supprimer définitivement votre compte et vos données'),
              trailing: Icon(Icons.chevron_right, color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(String? provider) {
    switch (provider) {
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      case 'email':
        return Icons.email;
      case 'anonymous':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m';
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    return '${hours}h ${minutes}m';
  }
}
