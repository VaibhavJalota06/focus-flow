import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase BEFORE building widget tree so auth listener can attach
  await SupabaseService.instance.initialize();

  runApp(
    const ProviderScope(
      child: TaskTrackerApp(),
    ),
  );

  // Initialize non-critical background services asynchronously
  NotificationService.instance.initialize().ignore();
  CloudSyncService.instance.startBackgroundSync();
}

class TaskTrackerApp extends ConsumerWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    // If still actively loading stored user session on cold start, show clean loading surface
    if (authState.isLoading && authState.user == null) {
      return MaterialApp(
        title: 'Focus Flow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primarySeed,
            ),
          ),
        ),
      );
    }

    final isUserLoggedIn = authState.user != null;
    final showMainApp = isUserLoggedIn || settings.onboardingCompleted;

    return MaterialApp(
      title: 'Focus Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: showMainApp
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => showMainApp
              ? const MainNavigationScreen()
              : const OnboardingScreen(),
        );
      },
      onUnknownRoute: (routeSettings) {
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => showMainApp
              ? const MainNavigationScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
