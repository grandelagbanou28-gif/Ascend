import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ascend/core/config/supabase_config.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static bool get isAuthenticated => currentUser != null;

  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  static String? get userEmail => currentUser?.email;

  static String? get userDisplayName => currentUser?.userMetadata?['display_name'];

  static String? get userAvatarUrl => currentUser?.userMetadata?['avatar_url'];

  static String? get userId => currentUser?.id;

  static DateTime? get userCreatedAt {
    if (currentUser?.createdAt == null) return null;
    return DateTime.tryParse(currentUser!.createdAt!);
  }

  static String? get userPhone => currentUser?.phone;

  static bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;

  static String? get authProvider {
    if (currentUser == null) return null;
    if (currentUser!.appMetadata['provider'] == 'email') return 'email';
    if (currentUser!.appMetadata['provider'] == 'google') return 'google';
    if (currentUser!.appMetadata['provider'] == 'apple') return 'apple';
    if (currentUser!.isAnonymous) return 'anonymous';
    return currentUser!.appMetadata['provider'];
  }

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (displayName != null) 'display_name': displayName,
      },
    );
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  static Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  // Sign in with Apple
  static Future<bool> signInWithApple() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  // Sign in anonymously
  static Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://password-reset/',
    );
  }

  // Update user profile
  static Future<UserResponse> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    return await _client.auth.updateUser(
      UserAttributes(
        data: {
          if (displayName != null) 'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ),
    );
  }

  // Update email
  static Future<UserResponse> updateEmail(String newEmail) async {
    return await _client.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  // Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    await _client.auth.verifyOTP(
      email: currentUser?.email ?? '',
      token: '',
      type: OtpType.signup,
    );
  }

  // Delete account
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    await _client.auth.admin.deleteUser(user.id);
    await _client.auth.signOut();
  }

  // Re-authenticate before sensitive operations
  static Future<AuthResponse> reAuthenticate({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
