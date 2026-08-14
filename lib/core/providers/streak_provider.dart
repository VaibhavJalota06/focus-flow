import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'task_provider.dart';

class StreakState {
  final int currentStreak;
  final int highestStreak;
  final int totalTasksCompleted;

  const StreakState({
    required this.currentStreak,
    required this.highestStreak,
    required this.totalTasksCompleted,
  });

  StreakState copyWith({
    int? currentStreak,
    int? highestStreak,
    int? totalTasksCompleted,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      highestStreak: highestStreak ?? this.highestStreak,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  static const _highestStreakKey = 'highest_streak_count';

  StreakNotifier()
      : super(const StreakState(
          currentStreak: 0,
          highestStreak: 0,
          totalTasksCompleted: 0,
        )) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final highest = prefs.getInt(_highestStreakKey) ?? 0;
    state = state.copyWith(highestStreak: highest);
  }

  void updateStreakFromTasks(List<TaskModel> tasks) {
    final completedTasks = tasks.where((t) => t.isCompleted && t.completedAt != null).toList();
    if (completedTasks.isEmpty) {
      state = state.copyWith(currentStreak: 0, totalTasksCompleted: 0);
      return;
    }

    // Map completion timestamps to unique DateOnly (yyyy-MM-dd) values
    final Set<String> completedDateStrings = {};
    for (final task in completedTasks) {
      final date = task.completedAt!;
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      completedDateStrings.add(dateStr);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;
    DateTime checkDate = completedDateStrings.contains(_toDateStr(today)) ? today : yesterday;

    while (completedDateStrings.contains(_toDateStr(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    final highest = streak > state.highestStreak ? streak : state.highestStreak;
    if (highest > state.highestStreak) {
      _saveHighestStreak(highest);
    }

    state = state.copyWith(
      currentStreak: streak,
      highestStreak: highest,
      totalTasksCompleted: completedTasks.length,
    );
  }

  String _toDateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveHighestStreak(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highestStreakKey, value);
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  final notifier = StreakNotifier();
  final tasks = ref.watch(taskProvider);
  notifier.updateStreakFromTasks(tasks);
  return notifier;
});
