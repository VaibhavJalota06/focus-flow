import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import 'task_provider.dart';
import 'streak_provider.dart';
import 'focus_provider.dart';

class ProductivityStats {
  final int productivityScore; // 0-100
  final String scoreExplanation;
  final int currentStreak;
  final int longestStreak;
  final int todayCompleted;
  final int todayTotal;
  final double todayCompletionRate;
  final int todayOverdue;
  final int todayFocusMinutes;

  final int weekCompleted;
  final int weekTotal;
  final double weekCompletionRate;
  final String bestDayOfWeek;

  final int monthCompleted;
  final int monthTotal;
  final double monthCompletionRate;
  final int monthFocusMinutes;

  final Map<DateTime, int> heatmapData; // Past 30 days completed count

  const ProductivityStats({
    required this.productivityScore,
    required this.scoreExplanation,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayCompleted,
    required this.todayTotal,
    required this.todayCompletionRate,
    required this.todayOverdue,
    required this.todayFocusMinutes,
    required this.weekCompleted,
    required this.weekTotal,
    required this.weekCompletionRate,
    required this.bestDayOfWeek,
    required this.monthCompleted,
    required this.monthTotal,
    required this.monthCompletionRate,
    required this.monthFocusMinutes,
    required this.heatmapData,
  });
}

final analyticsProvider = Provider<ProductivityStats>((ref) {
  final tasks = ref.watch(taskProvider);
  final focusSessionsAsync = ref.watch(focusSessionsProvider);
  final focusSessions = focusSessionsAsync.value ?? [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Today Stats
  final todayTasks = tasks.where((t) =>
      !t.isInbox &&
      t.date.year == today.year &&
      t.date.month == today.month &&
      t.date.day == today.day).toList();

  final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
  final todayTotal = todayTasks.length;
  final todayRate = todayTotal > 0 ? (todayCompleted / todayTotal) : 0.0;
  final todayOverdue = tasks.where((t) => t.isOverdue).length;

  final todayFocusMinutes = focusSessions
      .where((s) =>
          s.startedAt.year == today.year &&
          s.startedAt.month == today.month &&
          s.startedAt.day == today.day)
      .fold(0, (sum, s) => sum + s.durationMinutes);

  // Week Stats (Past 7 days)
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekTasks = tasks.where((t) =>
      !t.isInbox &&
      !t.date.isBefore(weekStart) &&
      !t.date.isAfter(today)).toList();
  final weekCompleted = weekTasks.where((t) => t.isCompleted).length;
  final weekTotal = weekTasks.length;
  final weekRate = weekTotal > 0 ? (weekCompleted / weekTotal) : 0.0;

  // Best day of week
  final dayCounts = <int, int>{};
  for (final t in weekTasks.where((t) => t.isCompleted)) {
    dayCounts[t.date.weekday] = (dayCounts[t.date.weekday] ?? 0) + 1;
  }
  int bestDayInt = DateTime.monday;
  int maxDayCount = 0;
  dayCounts.forEach((day, count) {
    if (count > maxDayCount) {
      maxDayCount = count;
      bestDayInt = day;
    }
  });
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final bestDayStr = maxDayCount > 0 ? dayNames[bestDayInt - 1] : 'None yet';

  // Month Stats (Past 30 days)
  final monthStart = today.subtract(const Duration(days: 30));
  final monthTasks = tasks.where((t) =>
      !t.isInbox &&
      !t.date.isBefore(monthStart) &&
      !t.date.isAfter(today)).toList();
  final monthCompleted = monthTasks.where((t) => t.isCompleted).length;
  final monthTotal = monthTasks.length;
  final monthRate = monthTotal > 0 ? (monthCompleted / monthTotal) : 0.0;

  final monthFocusMinutes = focusSessions
      .where((s) => !s.startedAt.isBefore(monthStart))
      .fold(0, (sum, s) => sum + s.durationMinutes);

  // Unified Heatmap & Streak from streakProvider
  final streakState = ref.watch(streakProvider);
  final heatmap = streakState.heatmapData;
  final currentStreak = streakState.currentStreak;
  final longestStreak = streakState.highestStreak;

  // Calculate Productivity Score (0-100)
  // 1. Task completion rate component (up to 50 pts)
  double scorePts = todayRate * 50.0;

  // 2. High / Urgent task bonus (up to 20 pts)
  final urgentToday = todayTasks.where((t) =>
      t.priority == TaskPriority.high || t.priority == TaskPriority.urgent);
  if (urgentToday.isNotEmpty) {
    final urgentCompleted = urgentToday.where((t) => t.isCompleted).length;
    scorePts += (urgentCompleted / urgentToday.length) * 20.0;
  } else {
    scorePts += todayRate * 20.0;
  }

  // 3. Streak consistency bonus (up to 15 pts)
  final streakBonus = (currentStreak * 3).clamp(0, 15);
  scorePts += streakBonus;

  // 4. Focus time bonus (up to 15 pts)
  final focusBonus = (todayFocusMinutes / 50 * 15).clamp(0.0, 15.0);
  scorePts += focusBonus;

  // 5. Overdue penalty (-5 pts per overdue task)
  scorePts -= (todayOverdue * 5);

  final finalScore = scorePts.round().clamp(0, 100);

  String explanation;
  if (finalScore >= 85) {
    explanation = 'Outstanding productivity today! Keep up the incredible streak.';
  } else if (finalScore >= 70) {
    explanation = 'Great progress! You are on track with your core priorities.';
  } else if (finalScore >= 50) {
    explanation = 'Good effort. Complete a few more tasks to boost your daily score.';
  } else {
    explanation = 'Focus on completing 1 or 2 high-priority tasks to build momentum.';
  }

  return ProductivityStats(
    productivityScore: finalScore,
    scoreExplanation: explanation,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    todayCompleted: todayCompleted,
    todayTotal: todayTotal,
    todayCompletionRate: todayRate,
    todayOverdue: todayOverdue,
    todayFocusMinutes: todayFocusMinutes,
    weekCompleted: weekCompleted,
    weekTotal: weekTotal,
    weekCompletionRate: weekRate,
    bestDayOfWeek: bestDayStr,
    monthCompleted: monthCompleted,
    monthTotal: monthTotal,
    monthCompletionRate: monthRate,
    monthFocusMinutes: monthFocusMinutes,
    heatmapData: heatmap,
  );
});
