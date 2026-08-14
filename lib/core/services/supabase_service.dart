import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  /// FocusFlow Cloud & Authentication Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zswgpvzcbwgddifozhcf.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpzd2dwdnpjYndnZGRpZm96aGNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2OTQ3MzcsImV4cCI6MjEwMjI3MDczN30.JPIuiud3TDD-INEKYqV7Et7O4KItMI389H5Jp-TqD5k',
  );
  static const String redirectCallbackUrl = String.fromEnvironment(
    'REDIRECT_CALLBACK_URL',
    defaultValue: 'focusflow://login-callback',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '392042986898-sk6utb5j0uhgmk48k1obb3d3h9ce4tsh.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: googleWebClientId,
    scopes: ['email', 'profile'],
  );

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Returns true if valid custom Supabase credentials have been configured
  bool get isLiveConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('dummy_anon_key');

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (isLiveConfigured) {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
          debug: kDebugMode,
        );
        _isInitialized = true;
        debugPrint('[SupabaseService] Initialized with live project: $supabaseUrl');
      } else {
        debugPrint('[SupabaseService] Running with placeholder configuration.');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Initialization warning (offline mode): $e');
    }
  }

  /// Native Google Sign-In with automatic Supabase OAuth fallback
  Future<UserModel?> signInWithGoogleNative() async {
    try {
      debugPrint('[SupabaseService] Starting native Google Sign-In...');
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[SupabaseService] Google sign in canceled by user');
        return null;
      }

      debugPrint('[SupabaseService] Google user selected: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (isLiveConfigured && _isInitialized && idToken != null) {
        try {
          final res = await client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          final user = userFromSupabaseUser(res.user);
          if (user != null) return user;
        } catch (e) {
          debugPrint('[SupabaseService] Supabase signInWithIdToken warning: $e');
        }
      }

      return UserModel(
        id: googleUser.id,
        name: googleUser.displayName ?? googleUser.email.split('@').first,
        email: googleUser.email,
        avatarUrl: googleUser.photoUrl ?? '🌟',
        bio: 'Connected via Google Account ✨',
        isGuest: false,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[SupabaseService] Native Google Sign-In failed ($e). Attempting Supabase OAuth fallback...');
      
      // Fallback: Launch Supabase Google OAuth Web flow
      if (isLiveConfigured && _isInitialized) {
        try {
          await client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: redirectCallbackUrl,
            authScreenLaunchMode: LaunchMode.platformDefault,
          );
          return null; // The OAuth redirect will be handled by the auth state listener
        } catch (oauthErr) {
          debugPrint('[SupabaseService] Supabase Google OAuth fallback error: $oauthErr');
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Launch Apple OAuth login flow (opens browser & redirects back)
  Future<bool> signInWithAppleOAuth() async {
    if (!isLiveConfigured || !_isInitialized) {
      debugPrint('[SupabaseService] Apple OAuth unavailable: Supabase not configured.');
      return false;
    }

    try {
      final res = await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectCallbackUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] Apple OAuth error: $e');
      rethrow;
    }
  }

  /// Converts a Supabase Auth User object to our local UserModel
  UserModel? userFromSupabaseUser(User? sbUser) {
    if (sbUser == null) return null;

    final metadata = sbUser.userMetadata ?? {};
    final fullName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        metadata['user_name'] as String? ??
        sbUser.email?.split('@').first ??
        'Google User';

    // Google provides profile photo in avatar_url or picture metadata
    final avatar = metadata['avatar_url'] as String? ??
        metadata['picture'] as String? ??
        metadata['avatarUrl'] as String? ??
        '🌟';

    return UserModel(
      id: sbUser.id,
      name: fullName,
      email: sbUser.email ?? 'user@gmail.com',
      avatarUrl: avatar,
      bio: 'Connected via Google Account ✨',
      isGuest: false,
      createdAt: DateTime.tryParse(sbUser.createdAt) ?? DateTime.now(),
    );
  }

  /// Sign out current Supabase session
  Future<void> signOut() async {
    if (isLiveConfigured && _isInitialized) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[SupabaseService] Sign out warning: $e');
      }
    }
  }
}
