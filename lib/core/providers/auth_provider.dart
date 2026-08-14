import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/cloud_sync_service.dart';
import '../services/supabase_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isGuest => user?.isGuest ?? true;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _userStorageKey = 'auth_user_json';

  AuthNotifier() : super(const AuthState()) {
    _loadStoredSession();
    _listenToSupabaseAuth();
  }

  void _listenToSupabaseAuth() {
    if (SupabaseService.instance.isLiveConfigured && SupabaseService.instance.isInitialized) {
      SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          final realUser = SupabaseService.instance.userFromSupabaseUser(session.user);
          if (realUser != null) {
            _persistUser(realUser);
            state = state.copyWith(user: realUser, isLoading: false, clearError: true);
            CloudSyncService.instance.syncAll();
          }
        }
      });
    }
  }

  Future<void> _loadStoredSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userStorageKey);
      if (userJson != null && userJson.isNotEmpty) {
        final user = UserModel.fromJson(userJson);
        state = state.copyWith(user: user, isLoading: false, clearError: true);
        if (!user.isGuest) {
          await prefs.setBool('onboardingCompleted', true);
          CloudSyncService.instance.syncAll();
        }
      } else {
        // Check if there is an active Supabase session
        if (SupabaseService.instance.isLiveConfigured && SupabaseService.instance.isInitialized) {
          final currentSbUser = SupabaseService.instance.client.auth.currentUser;
          if (currentSbUser != null) {
            final user = SupabaseService.instance.userFromSupabaseUser(currentSbUser);
            if (user != null) {
              await _persistUser(user);
              state = state.copyWith(user: user, isLoading: false, clearError: true);
              CloudSyncService.instance.syncAll();
              return;
            }
          }
        }
        state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
      }
    } catch (_) {
      state = state.copyWith(clearUser: true, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Please enter a valid email address.',
        );
        return false;
      }

      if (password.length < 6) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Password must be at least 6 characters.',
        );
        return false;
      }

      // Live Supabase Authentication
      if (SupabaseService.instance.isLiveConfigured && SupabaseService.instance.isInitialized) {
        try {
          final authRes = await SupabaseService.instance.client.auth.signInWithPassword(
            email: cleanEmail,
            password: password,
          );

          if (authRes.user != null) {
            final user = SupabaseService.instance.userFromSupabaseUser(authRes.user) ??
                UserModel(
                  id: authRes.user!.id,
                  name: cleanEmail.split('@').first,
                  email: cleanEmail,
                  avatarUrl: '🚀',
                  bio: 'Focused and productive ⚡',
                  isGuest: false,
                  createdAt: DateTime.now(),
                );

            await _persistUser(user);
            state = state.copyWith(user: user, isLoading: false, clearError: true);
            CloudSyncService.instance.syncAll();
            return true;
          }
        } on AuthException catch (ae) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: ae.message,
          );
          return false;
        } catch (e) {
          debugPrint('[AuthNotifier] Supabase login error: $e');
        }
      }

      // Fallback local mode
      final user = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanEmail.split('@').first.toUpperCase(),
        email: cleanEmail,
        avatarUrl: '🚀',
        bio: 'Focused and productive ⚡',
        isGuest: false,
        createdAt: DateTime.now(),
      );

      await _persistUser(user);
      state = state.copyWith(user: user, isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();

      if (cleanName.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'Name is required.');
        return false;
      }

      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Valid email is required.',
        );
        return false;
      }

      if (password.length < 6) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Password must be at least 6 characters.',
        );
        return false;
      }

      // Live Supabase Registration
      if (SupabaseService.instance.isLiveConfigured && SupabaseService.instance.isInitialized) {
        try {
          final authRes = await SupabaseService.instance.client.auth.signUp(
            email: cleanEmail,
            password: password,
            data: {
              'full_name': cleanName,
              'avatar_url': '🎯',
            },
          );

          if (authRes.user != null) {
            // Upsert into Supabase profiles table
            try {
              await SupabaseService.instance.client.from('profiles').upsert({
                'id': authRes.user!.id,
                'name': cleanName,
                'email': cleanEmail,
                'avatar_url': '🎯',
                'bio': 'New FocusFlow achiever ✨',
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              });
            } catch (pe) {
              debugPrint('[AuthNotifier] profiles upsert error: $pe');
            }

            final user = UserModel(
              id: authRes.user!.id,
              name: cleanName,
              email: cleanEmail,
              avatarUrl: '🎯',
              bio: 'New FocusFlow achiever ✨',
              isGuest: false,
              createdAt: DateTime.now(),
            );

            await _persistUser(user);
            state = state.copyWith(user: user, isLoading: false, clearError: true);
            CloudSyncService.instance.syncAll();
            return true;
          }
        } on AuthException catch (ae) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: ae.message,
          );
          return false;
        } catch (e) {
          debugPrint('[AuthNotifier] Supabase signUp error: $e');
        }
      }

      // Fallback local mode
      final user = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        avatarUrl: '🎯',
        bio: 'New FocusFlow achiever ✨',
        isGuest: false,
        createdAt: DateTime.now(),
      );

      await _persistUser(user);
      state = state.copyWith(user: user, isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await SupabaseService.instance.signInWithGoogleNative();
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      await _persistUser(user);
      state = state.copyWith(user: user, isLoading: false, clearError: true);
      CloudSyncService.instance.syncAll();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await SupabaseService.instance.signInWithAppleOAuth();
      if (!success) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final sbUser = SupabaseService.instance.isLiveConfigured
          ? SupabaseService.instance.client.auth.currentUser
          : null;

      final user = SupabaseService.instance.userFromSupabaseUser(sbUser) ??
          UserModel(
            id: 'usr_apple_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Apple User',
            email: 'user.apple@privaterelay.appleid.com',
            avatarUrl: '👑',
            bio: 'Connected via Apple ID ',
            isGuest: false,
            createdAt: DateTime.now(),
          );

      await _persistUser(user);
      state = state.copyWith(user: user, isLoading: false, clearError: true);
      CloudSyncService.instance.syncAll();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Apple Sign-In failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final guest = UserModel.guest();
    await _persistUser(guest);
    state = state.copyWith(user: guest, isLoading: false, clearError: true);
  }

  Future<void> updateProfile({String? name, String? avatarUrl, String? bio}) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(
      name: name?.trim(),
      avatarUrl: avatarUrl,
      bio: bio?.trim(),
    );
    await _persistUser(updated);
    state = state.copyWith(user: updated);

    // Sync to Supabase profile table & Auth metadata
    if (SupabaseService.instance.isLiveConfigured && SupabaseService.instance.isInitialized) {
      try {
        final currentSbUser = SupabaseService.instance.client.auth.currentUser;
        if (currentSbUser != null) {
          await SupabaseService.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                if (name != null) 'full_name': name.trim(),
                if (avatarUrl != null) 'avatar_url': avatarUrl,
                if (bio != null) 'bio': bio.trim(),
              },
            ),
          );

          await SupabaseService.instance.client.from('profiles').upsert({
            'id': currentSbUser.id,
            if (name != null) 'name': name.trim(),
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (bio != null) 'bio': bio.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('[AuthNotifier] Supabase profile sync error: $e');
      }
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await SupabaseService.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userStorageKey);
    await prefs.setBool('onboardingCompleted', false);
    state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
  }

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, user.toJson());
    if (!user.isGuest) {
      await prefs.setBool('onboardingCompleted', true);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
