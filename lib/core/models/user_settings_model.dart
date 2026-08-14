import 'package:flutter/material.dart';

class UserSettingsModel {
  final String userName;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int defaultReminderMinutes; // e.g. 10, 30, 60
  final int dailyGoal; // e.g. 5 tasks
  final String weekStartDay; // "Monday" or "Sunday"
  final bool onboardingCompleted;

  const UserSettingsModel({
    this.userName = 'Productive User',
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.defaultReminderMinutes = 10,
    this.dailyGoal = 5,
    this.weekStartDay = 'Monday',
    this.onboardingCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'defaultReminderMinutes': defaultReminderMinutes,
      'dailyGoal': dailyGoal,
      'weekStartDay': weekStartDay,
      'onboardingCompleted': onboardingCompleted ? 1 : 0,
    };
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    ThemeMode theme;
    switch (map['themeMode'] as String?) {
      case 'light':
        theme = ThemeMode.light;
        break;
      case 'dark':
        theme = ThemeMode.dark;
        break;
      default:
        theme = ThemeMode.system;
    }

    return UserSettingsModel(
      userName: (map['userName'] as String?) ?? 'Productive User',
      themeMode: theme,
      notificationsEnabled: (map['notificationsEnabled'] as int? ?? 1) == 1,
      defaultReminderMinutes: (map['defaultReminderMinutes'] as int?) ?? 10,
      dailyGoal: (map['dailyGoal'] as int?) ?? 5,
      weekStartDay: (map['weekStartDay'] as String?) ?? 'Monday',
      onboardingCompleted: (map['onboardingCompleted'] as int? ?? 0) == 1,
    );
  }

  UserSettingsModel copyWith({
    String? userName,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? defaultReminderMinutes,
    int? dailyGoal,
    String? weekStartDay,
    bool? onboardingCompleted,
  }) {
    return UserSettingsModel(
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
