import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings_model.dart';
import 'category_provider.dart';

class SettingsNotifier extends StateNotifier<UserSettingsModel> {
  final Ref ref;

  SettingsNotifier(this.ref) : super(const UserSettingsModel()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? 'Productive User';
    final themeStr = prefs.getString('themeMode') ?? 'system';
    final notif = prefs.getBool('notificationsEnabled') ?? true;
    final defaultReminder = prefs.getInt('defaultReminderMinutes') ?? 10;
    final dailyGoal = prefs.getInt('dailyGoal') ?? 5;
    final weekStart = prefs.getString('weekStartDay') ?? 'Monday';
    final onboarding = prefs.getBool('onboardingCompleted') ?? false;

    ThemeMode theme;
    switch (themeStr) {
      case 'light':
        theme = ThemeMode.light;
        break;
      case 'dark':
        theme = ThemeMode.dark;
        break;
      default:
        theme = ThemeMode.system;
    }

    state = UserSettingsModel(
      userName: name,
      themeMode: theme,
      notificationsEnabled: notif,
      defaultReminderMinutes: defaultReminder,
      dailyGoal: dailyGoal,
      weekStartDay: weekStart,
      onboardingCompleted: onboarding,
    );
  }

  Future<void> updateUserName(String name) async {
    state = state.copyWith(userName: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }

  Future<void> updateNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
  }

  Future<void> updateDefaultReminder(int minutes) async {
    state = state.copyWith(defaultReminderMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultReminderMinutes', minutes);
  }

  Future<void> updateDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
  }

  Future<void> updateWeekStart(String day) async {
    state = state.copyWith(weekStartDay: day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weekStartDay', day);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingCompleted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
  }

  Future<void> resetOnboarding() async {
    state = state.copyWith(onboardingCompleted: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', false);
  }

  Future<String> exportBackupJson() async {
    final repo = ref.read(repositoryProvider);
    final data = await repo.exportAllData();
    data['settings'] = state.toMap();
    return jsonEncode(data);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final repo = ref.read(repositoryProvider);
      await repo.importAllData(data);
      if (data['settings'] != null) {
        final settingsMap = data['settings'] as Map<String, dynamic>;
        state = UserSettingsModel.fromMap(settingsMap);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', state.userName);
        await prefs.setString('themeMode', state.themeMode.name);
        await prefs.setBool('notificationsEnabled', state.notificationsEnabled);
        await prefs.setInt('defaultReminderMinutes', state.defaultReminderMinutes);
        await prefs.setInt('dailyGoal', state.dailyGoal);
        await prefs.setString('weekStartDay', state.weekStartDay);
        await prefs.setBool('onboardingCompleted', state.onboardingCompleted);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettingsModel>((ref) {
  return SettingsNotifier(ref);
});
