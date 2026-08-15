import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/models/task_model.dart';
import 'package:focus_flow/core/providers/streak_provider.dart';

void main() {
  group('StreakCalculator Unit Tests', () {
    final baseDate = DateTime(2026, 8, 16); // Sunday

    TaskModel createTask({
      required String id,
      required DateTime date,
      required bool isCompleted,
      DateTime? completedAt,
    }) {
      return TaskModel(
        id: id,
        title: 'Task $id',
        categoryId: 'work',
        date: date,
        isCompleted: isCompleted,
        completedAt: completedAt ?? (isCompleted ? date : null),
        createdAt: date,
        updatedAt: date,
      );
    }

    test('Empty task list returns 0 current streak and 0 highest streak', () {
      final result = StreakCalculator.calculate(
        tasks: [],
        persistedHighest: 0,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(0));
      expect(result.highestStreak, equals(0));
      expect(result.totalTasksCompleted, equals(0));
    });

    test('Task completed today gives 1-day current streak', () {
      final tasks = [
        createTask(
          id: '1',
          date: baseDate,
          isCompleted: true,
          completedAt: DateTime(2026, 8, 16, 10, 30),
        ),
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(1));
      expect(result.highestStreak, equals(1));
      expect(result.totalTasksCompleted, equals(1));
    });

    test('No task completed today yet, but completed yesterday preserves streak', () {
      final yesterday = DateTime(2026, 8, 15);
      final twoDaysAgo = DateTime(2026, 8, 14);

      final tasks = [
        createTask(id: '1', date: twoDaysAgo, isCompleted: true),
        createTask(id: '2', date: yesterday, isCompleted: true),
        createTask(id: '3', date: baseDate, isCompleted: false), // Not completed today yet
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(2));
      expect(result.highestStreak, equals(2));
    });

    test('Completing today after yesterday extends streak to 3 days', () {
      final yesterday = DateTime(2026, 8, 15);
      final twoDaysAgo = DateTime(2026, 8, 14);

      final tasks = [
        createTask(id: '1', date: twoDaysAgo, isCompleted: true),
        createTask(id: '2', date: yesterday, isCompleted: true),
        createTask(id: '3', date: baseDate, isCompleted: true),
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(3));
      expect(result.highestStreak, equals(3));
    });

    test('Gap in completion breaks current streak', () {
      final threeDaysAgo = DateTime(2026, 8, 13);
      final fourDaysAgo = DateTime(2026, 8, 12);

      // Aug 12 & 13 completed, but Aug 14 & 15 missed, today is Aug 16
      final tasks = [
        createTask(id: '1', date: fourDaysAgo, isCompleted: true),
        createTask(id: '2', date: threeDaysAgo, isCompleted: true),
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(0));
      expect(result.highestStreak, equals(2)); // Historical longest is preserved
    });

    test('Multiple completed tasks on the same day count as 1 streak day', () {
      final tasks = [
        createTask(id: '1', date: baseDate, isCompleted: true),
        createTask(id: '2', date: baseDate, isCompleted: true),
        createTask(id: '3', date: baseDate, isCompleted: true),
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(1));
      expect(result.totalTasksCompleted, equals(3));
    });

    test('Persisted highest streak is respected if greater than current tasks history', () {
      final tasks = [
        createTask(id: '1', date: baseDate, isCompleted: true),
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        persistedHighest: 15,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(1));
      expect(result.highestStreak, equals(15));
    });

    test('Task completed with null completedAt falls back to task.date', () {
      final yesterday = DateTime(2026, 8, 15);
      final tasks = <TaskModel>[
        TaskModel(
          id: 'null-completed-at',
          title: 'Legacy task',
          categoryId: 'work',
          date: yesterday,
          isCompleted: true,
          completedAt: null,
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
      ];

      final result = StreakCalculator.calculate(
        tasks: tasks,
        referenceDate: baseDate,
      );

      expect(result.currentStreak, equals(1));
    });
  });
}
