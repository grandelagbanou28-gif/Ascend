import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ascend/core/config/supabase_config.dart';
import 'package:ascend/data/models/user_profile.dart';

class ProfileService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Get current user profile
  static Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // Profile doesn't exist, create one
      return await createProfile(user);
    }
  }

  // Create a new profile
  static Future<UserProfile> createProfile(User user) async {
    final profile = UserProfile(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] ?? '',
      username: user.userMetadata?['email']?.split('@').first,
      avatarUrl: user.userMetadata?['avatar_url'],
      createdAt: DateTime.now(),
    );

    await _client.from('profiles').insert(profile.toJson());

    return profile;
  }

  // Update profile
  static Future<UserProfile> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bannerUrl,
    String? country,
    String? language,
    String? timezone,
    String? favoriteQuote,
    String? primaryColor,
    String? theme,
    String? profileIcon,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bannerUrl != null) updates['banner_url'] = bannerUrl;
    if (country != null) updates['country'] = country;
    if (language != null) updates['language'] = language;
    if (timezone != null) updates['timezone'] = timezone;
    if (favoriteQuote != null) updates['favorite_quote'] = favoriteQuote;
    if (primaryColor != null) updates['primary_color'] = primaryColor;
    if (theme != null) updates['theme'] = theme;
    if (profileIcon != null) updates['profile_icon'] = profileIcon;

    await _client.from('profiles').update(updates).eq('id', user.id);

    // Also update Supabase Auth metadata
    await _client.auth.updateUser(
      UserAttributes(data: {
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }),
    );

    return (await getCurrentProfile())!;
  }

  // Update stats
  static Future<void> updateStats({
    int? level,
    int? xp,
    int? currentStreak,
    int? bestStreak,
    int? totalHabits,
    int? challengesCompleted,
    int? totalFocusTime,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (level != null) updates['level'] = level;
    if (xp != null) updates['xp'] = xp;
    if (currentStreak != null) updates['current_streak'] = currentStreak;
    if (bestStreak != null) updates['best_streak'] = bestStreak;
    if (totalHabits != null) updates['total_habits'] = totalHabits;
    if (challengesCompleted != null) updates['challenges_completed'] = challengesCompleted;
    if (totalFocusTime != null) updates['total_focus_time'] = totalFocusTime;

    await _client.from('profiles').update(updates).eq('id', user.id);
  }

  // Add XP and check level up
  static Future<bool> addXp(int amount) async {
    final profile = await getCurrentProfile();
    if (profile == null) return false;

    int newXp = profile.xp + amount;
    int newLevel = profile.level;
    bool leveledUp = false;

    while (newXp >= profile.xpForNextLevel) {
      newXp -= profile.xpForNextLevel;
      newLevel++;
      leveledUp = true;
    }

    await updateStats(
      level: newLevel,
      xp: newXp,
    );

    return leveledUp;
  }

  // Check username availability
  static Future<bool> isUsernameAvailable(String username) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }

  // Delete profile
  static Future<void> deleteProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').delete().eq('id', user.id);
  }
}
