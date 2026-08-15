import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'task_provider.dart';

class StreakState {
  final int currentStreak;
  final int highestStreak;
  final int totalTasksCompleted;
  final Set<String> activeDates;
  final Map<DateTime, int> heatmapData;

  const StreakState({
    required this.currentStreak,
    required this.highestStreak,
    required this.totalTasksCompleted,
    this.activeDates = const {},
    this.heatmapData = const {},
  });

  StreakState copyWith({
    int? currentStreak,
    int? highestStreak,
    int? totalTasksCompleted,
    Set<String>? activeDates,
    Map<DateTime, int>? heatmapData,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      highestStreak: highestStreak ?? this.highestStreak,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      activeDates: activeDates ?? this.activeDates,
      heatmapData: heatmapData ?? this.heatmapData,
    );
  }
}

class StreakCalculationResult {
  final int currentStreak;
  final int highestStreak;
  final int totalTasksCompleted;
  final Set<String> completedDates;
  final Map<DateTime, int> heatmapData;

  const StreakCalculationResult({
    required this.currentStreak,
    required this.highestStreak,
    required this.totalTasksCompleted,
    required this.completedDates,
    required this.heatmapData,
  });
}

class StreakCalculator {
  static String toDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static DateTime toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static StreakCalculationResult calculate({
    required List<TaskModel> tasks,
    int persistedHighest = 0,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = toDateOnly(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    // Get all completed tasks
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    if (completedTasks.isEmpty) {
      return StreakCalculationResult(
        currentStreak: 0,
        highestStreak: persistedHighest,
        totalTasksCompleted: 0,
        completedDates: {},
        heatmapData: _generateHeatmap(completedTasks, today, 30),
      );
    }

    // Map each completed task to its completion date (fallback to task.date / updatedAt)
    final Set<String> completedDateStrings = {};
    for (final task in completedTasks) {
      final date = task.completedAt ?? task.date;
      completedDateStrings.add(toDateKey(date));
    }

    // 1. Calculate Current Streak
    int currentStreak = 0;
    final todayStr = toDateKey(today);
    final yesterdayStr = toDateKey(yesterday);

    // If completed today, streak counts backwards starting from today.
    // If not completed today yet, streak is preserved from yesterday.
    DateTime checkDate;
    if (completedDateStrings.contains(todayStr)) {
      checkDate = today;
    } else if (completedDateStrings.contains(yesterdayStr)) {
      checkDate = yesterday;
    } else {
      checkDate = today; // Will terminate while loop on first check -> 0
    }

    while (completedDateStrings.contains(toDateKey(checkDate))) {
      currentStreak++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    // 2. Calculate Longest Streak from all historical dates
    final sortedDates = completedDateStrings.map((s) {
      final parts = s.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }).toList()..sort();

    int maxHistoryStreak = 0;
    int runningStreak = 0;
    DateTime? prevDate;

    for (final d in sortedDates) {
      if (prevDate == null) {
        runningStreak = 1;
      } else {
        final expectedNext = DateTime(prevDate.year, prevDate.month, prevDate.day + 1);
        if (d.year == expectedNext.year && d.month == expectedNext.month && d.day == expectedNext.day) {
          runningStreak++;
        } else {
          runningStreak = 1;
        }
      }
      if (runningStreak > maxHistoryStreak) {
        maxHistoryStreak = runningStreak;
      }
      prevDate = d;
    }

    final calculatedHighest = maxHistoryStreak > currentStreak ? maxHistoryStreak : currentStreak;
    final finalHighest = calculatedHighest > persistedHighest ? calculatedHighest : persistedHighest;

    return StreakCalculationResult(
      currentStreak: currentStreak,
      highestStreak: finalHighest,
      totalTasksCompleted: completedTasks.length,
      completedDates: completedDateStrings,
      heatmapData: _generateHeatmap(completedTasks, today, 30),
    );
  }

  static Map<DateTime, int> _generateHeatmap(List<TaskModel> completedTasks, DateTime today, int days) {
    final heatmap = <DateTime, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day - i);
      final count = completedTasks.where((t) {
        final date = t.completedAt ?? t.date;
        return date.year == day.year && date.month == day.month && date.day == day.day;
      }).length;
      heatmap[day] = count;
    }
    return heatmap;
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  static const _highestStreakKey = 'highest_streak_count';
  final Ref _ref;
  int _persistedHighest = 0;

  StreakNotifier(this._ref)
      : super(const StreakState(
          currentStreak: 0,
          highestStreak: 0,
          totalTasksCompleted: 0,
        )) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistedHighest = prefs.getInt(_highestStreakKey) ?? 0;
    } catch (_) {}

    _recompute(_ref.read(taskProvider));

    _ref.listen<List<TaskModel>>(taskProvider, (_, nextTasks) {
      _recompute(nextTasks);
    });
  }

  void _recompute(List<TaskModel> tasks) {
    final result = StreakCalculator.calculate(
      tasks: tasks,
      persistedHighest: _persistedHighest,
    );

    if (result.highestStreak > _persistedHighest) {
      _persistedHighest = result.highestStreak;
      _saveHighestStreak(_persistedHighest);
    }

    state = StreakState(
      currentStreak: result.currentStreak,
      highestStreak: result.highestStreak,
      totalTasksCompleted: result.totalTasksCompleted,
      activeDates: result.completedDates,
      heatmapData: result.heatmapData,
    );
  }

  Future<void> _saveHighestStreak(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highestStreakKey, value);
    } catch (_) {}
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier(ref);
});
